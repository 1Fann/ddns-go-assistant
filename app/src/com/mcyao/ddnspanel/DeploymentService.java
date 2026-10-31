package com.mcyao.ddnspanel;

import android.app.*;
import android.content.*;
import android.os.*;
import org.json.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.net.ssl.HttpsURLConnection;

/** Foreground work outlives Activity rotation. No credentials are read by Java. */
public final class DeploymentService extends Service {
    public static final String RECOMMENDED="v6.17.7";
    private static final String PIN="1e9dd881e81e5043820f145a82d0df71bfe9b66f4a4d8813bdea5a7f131925fd";
    private static final String API="https://api.github.com/repos/jeessy2/ddns-go/releases/latest";
    static final AtomicBoolean ACTIVE=new AtomicBoolean(false);
    static volatile int message=0;
    static volatile String version="",error="";
    static volatile int percent=-1;
    static volatile boolean success=false,paused=false;
    private PowerManager.WakeLock wake;
    static final String[] PAYLOAD={"control.sh","daemon.sh","watchdog.sh","process.sh","interval.sh","control-version","ipv6.sh","filter-ipv6.awk","wake.sh","99-ddns-go.sh","install.sh","LICENSE.ddns-go"};
    public IBinder onBind(Intent intent){return null;}
    public int onStartCommand(Intent intent,int flags,int id){
        if(intent==null){stopSelf();return START_NOT_STICKY;}
        if(!ACTIVE.compareAndSet(false,true))return START_NOT_STICKY;
        message=R.string.deploy_checking;version="";error="";percent=-1;success=false;paused=false;
        NotificationManager nm=getSystemService(NotificationManager.class);
        nm.createNotificationChannel(new NotificationChannel("deployment",getString(R.string.deploy_channel),NotificationManager.IMPORTANCE_LOW));
        startForeground(21,notification());
        wake=((PowerManager)getSystemService(POWER_SERVICE)).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,getPackageName()+":deployment");
        wake.acquire(15*60*1000L);
        boolean latest=intent.getBooleanExtra("latest",false);
        new Thread(()->{
            try{deploy(latest);success=true;stage(paused?R.string.deploy_done_paused:R.string.deploy_done);}
            catch(Exception e){
                android.util.Log.w("DDNS-Deploy","stage="+getResources().getResourceEntryName(message)+"; error="+e.getClass().getSimpleName());
                error=safeError(e);stage(R.string.deploy_failed);
            }
            finally{if(wake!=null&&wake.isHeld())wake.release();ACTIVE.set(false);stopForeground(STOP_FOREGROUND_REMOVE);stopSelf();}
        },"ddns-deployment").start();
        return START_NOT_STICKY;
    }
    private Notification notification(){
        Intent open=new Intent(this,DeploymentActivity.class);
        PendingIntent pending=PendingIntent.getActivity(this,0,open,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
        return new Notification.Builder(this,"deployment").setSmallIcon(android.R.drawable.stat_sys_download).setContentTitle(getString(R.string.deploy_title)).setContentText(getString(message)).setContentIntent(pending).setOngoing(true).build();
    }
    private void stage(int text){message=text;getSystemService(NotificationManager.class).notify(21,notification());}
    private void deploy(boolean latest) throws Exception {
        RootShell.Result pre=RootShell.run("id -u; [ -x "+RootShell.busybox()+" ] || exit 20; [ \"$(getprop ro.product.cpu.abi)\" = arm64-v8a ] || exit 21; if [ -e "+RootShell.BASE+" ] || [ -e /data/adb/service.d/99-ddns-go.sh ]; then [ -f "+RootShell.BASE+"/.ddns-go-android-root ] || exit 22; fi",25);
        if(!pre.output.startsWith("0\n"))throw new IOException("ROOT_REQUIRED");
        if(pre.code!=0)throw new IOException(pre.code==20?"ENVIRONMENT_UNSUPPORTED":pre.code==21?"ARCHITECTURE_UNSUPPORTED":pre.code==22?"EXISTING_INSTALLATION":"ROOT_REQUIRED");
        String tag=RECOMMENDED,hash=PIN;
        String assetUrl="https://github.com/jeessy2/ddns-go/releases/download/"+tag+"/ddns-go_"+tag.substring(1)+"_android_arm64.tar.gz";
        stage(R.string.deploy_resolving);
        if(latest){
            JSONObject release=new JSONObject(text(API));
            tag=release.getString("tag_name");
            if(release.optBoolean("draft")||release.optBoolean("prerelease")||!tag.matches("v[0-9]+\\.[0-9]+\\.[0-9]+"))throw new IOException("RELEASE_UNSUPPORTED");
            String expected="ddns-go_"+tag.substring(1)+"_android_arm64.tar.gz";
            String digest="",checksums="";boolean exists=false;
            JSONArray assets=release.getJSONArray("assets");
            for(int i=0;i<assets.length();i++){
                JSONObject a=assets.getJSONObject(i);String name=a.getString("name");
                if(name.equals(expected)){
                    exists=true;digest=a.optString("digest","");
                    String candidate=a.getString("url");
                    if(!candidate.matches("https://api\\.github\\.com/repos/jeessy2/ddns-go/releases/assets/[0-9]+"))throw new IOException("RELEASE_UNSUPPORTED");
                    assetUrl=candidate;
                }
                if(name.equals("checksums.txt"))checksums="https://github.com/jeessy2/ddns-go/releases/download/"+tag+"/checksums.txt";
            }
            if(!exists)throw new IOException("RELEASE_UNSUPPORTED");
            if(digest.matches("sha256:[a-fA-F0-9]{64}"))hash=digest.substring(7);
            else {
                hash="";
                if(!checksums.isEmpty())for(String line:text(checksums).split("\\r?\\n")){
                    String[] fields=line.trim().split("\\s+",2);
                    if(fields.length==2&&(fields[1].equals(expected)||fields[1].equals("*"+expected))){if(!hash.isEmpty())throw new IOException("CHECKSUM_MISSING");hash=fields[0];}
                }
                if(!hash.matches("[a-fA-F0-9]{64}"))throw new IOException("CHECKSUM_MISSING");
            }
        }
        version=tag;
        File dir=new File(getFilesDir(),"deployment");if(!dir.exists()&&!dir.mkdir())throw new IOException("STORAGE_ERROR");
        File archive=new File(dir,"engine.tar.gz"),binary=new File(dir,"ddns-go");
        try{
            stage(R.string.deploy_downloading);percent=0;
            String downloadUrl=assetUrl;
            for(int attempt=0;;attempt++){
                try{stage(R.string.deploy_downloading);download(downloadUrl,archive);break;}
                catch(java.net.SocketTimeoutException|java.net.SocketException|java.net.UnknownHostException transientFailure){
                    if(attempt>=2)throw transientFailure;
                    stage(R.string.deploy_retry);percent=-1;Thread.sleep(1000L*(attempt+1));
                }
            }
            stage(R.string.deploy_verifying);percent=-1;
            ReleaseArchive.verify(archive,hash);ReleaseArchive.extract(archive,binary);
            for(String name:PAYLOAD)try(InputStream in=getAssets().open("runtime/"+name);OutputStream out=new FileOutputStream(new File(dir,name))){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}
            try(OutputStream out=new FileOutputStream(new File(dir,"engine-version"))){out.write((tag+"\n").getBytes(StandardCharsets.US_ASCII));}
            stage(R.string.deploy_installing);
            RootShell.Result result=RootShell.run(RootShell.busybox()+" ash "+RootShell.quote(new File(dir,"install.sh").getAbsolutePath())+" --app",180);
            if(result.code!=0||!result.output.contains("INSTALL_OK")){
                if(result.output.contains("RECOVERY_REQUIRED"))throw new IOException("RECOVERY_REQUIRED");
                if(result.output.contains("ROLLED_BACK"))throw new IOException("INSTALL_ROLLED_BACK");
                throw new IOException("INSTALL_FAILED");
            }
            paused=result.output.contains("INSTALL_OK_PAUSED");
        }finally{
            archive.delete();binary.delete();for(String name:PAYLOAD)new File(dir,name).delete();new File(dir,"engine-version").delete();dir.delete();
        }
    }
    private HttpsURLConnection connect(String address) throws Exception {
        URL url=new URL(address);
        for(int hop=0;hop<6;hop++){
            String host=url.getHost();
            if(!url.getProtocol().equals("https")||url.getUserInfo()!=null||(url.getPort()!=-1&&url.getPort()!=443)||!(host.equals("api.github.com")||host.equals("github.com")||host.equals("release-assets.githubusercontent.com")||host.equals("objects.githubusercontent.com")))throw new IOException("DOWNLOAD_HOST_REJECTED");
            HttpsURLConnection c=(HttpsURLConnection)url.openConnection();c.setInstanceFollowRedirects(false);c.setConnectTimeout(20000);c.setReadTimeout(30000);
            boolean metadata=host.equals("api.github.com")&&!url.getPath().contains("/releases/assets/");
            c.setRequestProperty("User-Agent","ddns-go-android-root/3.2");c.setRequestProperty("Accept",metadata?"application/vnd.github+json":"application/octet-stream");
            int code=c.getResponseCode();
            if(code==301||code==302||code==303||code==307||code==308){String next=c.getHeaderField("Location");c.disconnect();if(next==null)throw new IOException("DOWNLOAD_FAILED");url=new URL(url,next);continue;}
            if(code!=200){c.disconnect();throw new IOException(code==403||code==429?"GITHUB_RATE_LIMIT":"DOWNLOAD_FAILED");}
            return c;
        }
        throw new IOException("DOWNLOAD_FAILED");
    }
    private String text(String address) throws Exception {
        HttpsURLConnection c=connect(address);
        try(InputStream in=c.getInputStream();ByteArrayOutputStream out=new ByteArrayOutputStream()){
            byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1){if(out.size()+n>2*1024*1024)throw new IOException("METADATA_TOO_LARGE");out.write(b,0,n);}return new String(out.toByteArray(),StandardCharsets.UTF_8);
        }finally{c.disconnect();}
    }
    private void download(String address,File target) throws Exception {
        HttpsURLConnection c=connect(address);long length=c.getContentLengthLong(),total=0,start=System.nanoTime();
        try(InputStream in=c.getInputStream();OutputStream out=new FileOutputStream(target)){
            byte[] b=new byte[16384];int n;while((n=in.read(b))!=-1){total+=n;if(total>64L*1024*1024)throw new IOException("DOWNLOAD_TOO_LARGE");if(System.nanoTime()-start>180_000_000_000L)throw new java.net.SocketTimeoutException();out.write(b,0,n);percent=length>0?(int)Math.min(100,total*100/length):-1;}
            if(length>0&&total!=length)throw new IOException("DOWNLOAD_FAILED");
        }finally{c.disconnect();}
    }
    private static String safeError(Exception e){
        if(e instanceof java.net.SocketTimeoutException)return "NETWORK_TIMEOUT";
        if(e instanceof java.net.UnknownHostException)return "DNS_LOOKUP_FAILED";
        if(e instanceof javax.net.ssl.SSLException)return "TLS_FAILED";
        if(e instanceof org.json.JSONException)return "RELEASE_METADATA_INVALID";
        String s=e.getMessage();
        // Never put response bodies, request URLs, root output or credentials into UI/logcat.
        if(s!=null&&s.matches("[A-Z_]{3,40}"))return s;
        return "NETWORK_OR_SYSTEM_ERROR";
    }
}
