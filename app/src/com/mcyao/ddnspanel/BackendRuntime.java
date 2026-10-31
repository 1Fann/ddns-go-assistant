package com.mcyao.ddnspanel;

import android.content.Context;
import java.io.*;

/** Update bundled helpers through the same transactional installer as deployment.
 * The engine is copied locally, and credentials remain inside root-only paths. */
final class BackendRuntime {
    static synchronized void ensureCurrent(Context context) throws Exception {
        RootShell.Result probe=RootShell.run("[ \"$(id -u)\" = 0 ] || exit 1; "
            +"if [ ! -f /data/adb/ddns-go/.ddns-go-android-root ]; then echo SKIP; "
            +"elif [ \"$(cat /data/adb/ddns-go/control-version 2>/dev/null)\" = 3.3.4 ]; then echo CURRENT; "
            +"else echo UPDATE; fi",10);
        if(probe.code!=0)throw new IOException("ROOT_UNAVAILABLE");
        if(!probe.output.trim().equals("UPDATE"))return;
        File dir=new File(context.getFilesDir(),"controls-update");
        if(!dir.isDirectory()&&!dir.mkdirs())throw new IOException("STAGING_FAILED");
        try {
            for(String name:DeploymentService.PAYLOAD){
                try(InputStream in=context.getAssets().open("runtime/"+name);
                    OutputStream out=new FileOutputStream(new File(dir,name))){
                    byte[] buffer=new byte[8192];int count;
                    while((count=in.read(buffer))!=-1)out.write(buffer,0,count);
                }
            }
            String target=RootShell.quote(dir.getAbsolutePath());
            RootShell.Result result=RootShell.run("set -eu; umask 077; "
                +"[ -f /data/adb/ddns-go/.ddns-go-android-root ]; "
                +"[ ! -L /data/adb/ddns-go/ddns-go ] && [ ! -L /data/adb/ddns-go/engine-version ]; "
                +"cp /data/adb/ddns-go/ddns-go "+target+"/ddns-go; "
                +"cp /data/adb/ddns-go/engine-version "+target+"/engine-version; "
                +RootShell.busybox()+" ash "+target+"/install.sh --upgrade",150);
            if(result.code!=0){
                String status="UNKNOWN";
                for(String line:result.output.split("\\n"))if(line.trim().matches("[A-Z_]{3,40}"))status=line.trim();
                android.util.Log.w("DDNS-Control","helper_update_exit="+result.code+"; status="+status);
                // Keep the existing backend usable while a concurrent install
                // holds the lock. The next status refresh retries the update.
                return;
            }
        } finally {
            File[] files=dir.listFiles();
            if(files!=null)for(File file:files)file.delete();
            dir.delete();
        }
    }
}
