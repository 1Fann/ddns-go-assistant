package com.mcyao.ddnspanel;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.widget.*;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.*;

public final class MainActivity extends Activity {
    private static final int INK=Color.rgb(21,43,68), MUTED=Color.rgb(104,123,143), ACCENT=Color.rgb(0,118,174), BG=Color.rgb(243,247,251);
    private static final String CONTROL="/data/adb/ddns-go/control.sh ";
    private final ExecutorService worker=Executors.newSingleThreadExecutor();
    private final Handler handler=new Handler();
    private TextView status, subtitle, address, synced, wakeHint, engineVersion, notice, intervalHint;
    private Switch serviceSwitch, wakeSwitch;
    private Button checkButton, refreshButton, logButton, deployButton, syncButton, intervalButton;
    private ProgressBar progress;
    private boolean binding=false, busy=false, resumed=false;
    private String logs="";
    private int intervalSeconds=300;
    private boolean controlsSupported=false, backendRunning=false;
    private final Runnable poll=new Runnable(){public void run(){if(resumed){load(null);handler.postDelayed(this,15000);}}};

    public void onCreate(Bundle saved){
        super.onCreate(saved);
        getWindow().setStatusBarColor(BG);getWindow().setNavigationBarColor(BG);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR|View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
        ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);scroll.setBackgroundColor(BG);
        LinearLayout page=new LinearLayout(this);page.setOrientation(LinearLayout.VERTICAL);page.setPadding(dp(22),dp(20),dp(22),dp(24));page.setFocusableInTouchMode(true);scroll.addView(page);
        TextView eyebrow=text("DDNS-GO  /  ANDROID",11,ACCENT,true);eyebrow.setLetterSpacing(.12f);page.addView(eyebrow);
        TextView title=text(getString(R.string.app_name),26,INK,true);add(page,title,8,4);
        add(page,text(getString(R.string.tagline),14,MUTED,false),0,18);

        LinearLayout hero=card(INK);GradientDrawable heroBackground=new GradientDrawable(GradientDrawable.Orientation.TL_BR,new int[]{INK,Color.rgb(15,80,112)});heroBackground.setCornerRadius(dp(20));hero.setBackground(heroBackground);page.addView(hero);
        add(hero,text(getString(R.string.backend_status),11,Color.rgb(166,211,235),true),0,6);
        status=text(getString(R.string.connecting),23,Color.WHITE,true);hero.addView(status);
        subtitle=text(getString(R.string.reading_service),13,Color.rgb(196,224,240),false);add(hero,subtitle,6,14);
        engineVersion=text("ddns-go",12,Color.rgb(115,218,255),true);hero.addView(engineVersion);
        progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);progress.setIndeterminate(true);progress.setIndeterminateTintList(ColorStateList.valueOf(ACCENT));
        LinearLayout.LayoutParams pp=new LinearLayout.LayoutParams(-1,dp(3));pp.topMargin=dp(8);pp.bottomMargin=dp(8);page.addView(progress,pp);
        deployButton=button(getString(R.string.deploy_entry),false);add(page,deployButton,0,10);
        deployButton.setOnClickListener(v->startActivity(new android.content.Intent(this,DeploymentActivity.class)));
        checkButton=button(getString(R.string.open_management),true);add(page,checkButton,0,5);checkButton.setOnClickListener(v->startActivity(new android.content.Intent(this,WebActivity.class)));
        TextView manageHint=text(getString(R.string.management_hint),12,MUTED,false);manageHint.setGravity(Gravity.CENTER);add(page,manageHint,0,18);
        syncButton=button(getString(R.string.sync_now),true);add(page,syncButton,0,6);
        syncButton.setOnClickListener(v->load("sync"));
        add(page,text(getString(R.string.sync_hint),12,MUTED,false),0,16);

        LinearLayout settings=card(Color.WHITE);page.addView(settings);
        serviceSwitch=toggle(settings,getString(R.string.background_run),getString(R.string.background_hint));
        divider(settings);
        wakeSwitch=toggle(settings,getString(R.string.keep_awake),null);
        wakeHint=text(getString(R.string.wake_initial),12,MUTED,false);add(settings,wakeHint,3,1);
        divider(settings);
        intervalButton=button(getString(R.string.check_interval),false);settings.addView(intervalButton);
        intervalHint=text(getString(R.string.interval_value,5),12,MUTED,false);add(settings,intervalHint,6,0);
        intervalButton.setOnClickListener(v->editInterval());
        serviceSwitch.setOnCheckedChangeListener((button,value)->{if(!binding)load(value?"start":"stop");});
        wakeSwitch.setOnCheckedChangeListener((button,value)->{if(!binding)load(value?"wake-on":"wake-off");});
        add(page,text(getString(R.string.wake_explanation),12,MUTED,false),9,16);

        LinearLayout info=card(Color.WHITE);page.addView(info);
        add(info,text(getString(R.string.wifi_ipv6),12,MUTED,true),0,8);
        address=text(getString(R.string.reading),15,INK,false);address.setTypeface(Typeface.MONOSPACE);address.setTextIsSelectable(true);info.addView(address);
        synced=text("",12,ACCENT,false);add(info,synced,9,0);
        notice=text("",13,Color.rgb(160,94,22),false);add(info,notice,9,0);

        LinearLayout actions=new LinearLayout(this);actions.setOrientation(LinearLayout.HORIZONTAL);add(page,actions,16,0);
        refreshButton=button(getString(R.string.refresh_status),false);logButton=button(getString(R.string.view_logs),false);
        LinearLayout.LayoutParams left=new LinearLayout.LayoutParams(0,-2,1);left.rightMargin=dp(8);actions.addView(refreshButton,left);
        actions.addView(logButton,new LinearLayout.LayoutParams(0,dp(48),1));
        refreshButton.setOnClickListener(v->load(null));logButton.setOnClickListener(v->showLogs());
        add(page,text(getString(R.string.about),12,MUTED,false),20,0);
        setContentView(scroll);load(null);
    }
    private int dp(int x){return Math.round(x*getResources().getDisplayMetrics().density);}
    private TextView text(String s,int size,int color,boolean bold){TextView t=new TextView(this);t.setText(s);t.setTextSize(size);t.setTextColor(color);t.setLineSpacing(dp(3),1);if(bold)t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);return t;}
    private GradientDrawable rounded(int color,int radius){GradientDrawable d=new GradientDrawable();d.setColor(color);d.setCornerRadius(dp(radius));return d;}
    private LinearLayout card(int color){LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.VERTICAL);l.setPadding(dp(20),dp(20),dp(20),dp(20));l.setBackground(rounded(color,20));return l;}
    private void add(LinearLayout p,View v,int top,int bottom){LinearLayout.LayoutParams a=new LinearLayout.LayoutParams(-1,-2);a.topMargin=dp(top);a.bottomMargin=dp(bottom);p.addView(v,a);}
    private void divider(LinearLayout p){View v=new View(this);v.setBackgroundColor(Color.rgb(231,238,246));LinearLayout.LayoutParams a=new LinearLayout.LayoutParams(-1,dp(1));a.topMargin=dp(14);a.bottomMargin=dp(14);p.addView(v,a);}
    private Switch toggle(LinearLayout p,String title,String hint){Switch s=new Switch(this);s.setText(title);s.setTextSize(16);s.setTextColor(INK);s.setTypeface(Typeface.DEFAULT,Typeface.BOLD);s.setPadding(0,dp(5),0,dp(5));s.setSwitchPadding(dp(15));s.setMinHeight(dp(42));
        s.setThumbTintList(new ColorStateList(new int[][]{new int[]{android.R.attr.state_checked},new int[]{}},new int[]{ACCENT,Color.rgb(151,170,186)}));
        s.setTrackTintList(new ColorStateList(new int[][]{new int[]{android.R.attr.state_checked},new int[]{}},new int[]{Color.rgb(165,214,238),Color.rgb(218,227,237)}));p.addView(s);if(hint!=null)add(p,text(hint,12,MUTED,false),2,0);return s;}
    private Button button(String label,boolean primary){Button b=new Button(this);b.setText(label);b.setTextSize(13);b.setAllCaps(false);b.setMinHeight(dp(50));b.setTextColor(primary?Color.WHITE:INK);b.setBackground(rounded(primary?ACCENT:Color.rgb(228,237,247),13));return b;}
    private void setBusy(boolean value){busy=value;progress.setVisibility(value?View.VISIBLE:View.INVISIBLE);serviceSwitch.setEnabled(!value);wakeSwitch.setEnabled(!value);checkButton.setEnabled(!value);refreshButton.setEnabled(!value);deployButton.setEnabled(!value);syncButton.setEnabled(!value&&controlsSupported&&backendRunning);intervalButton.setEnabled(!value&&controlsSupported);}
    private static class Result {int code;String output;Result(int c,String o){code=c;output=o;}}
    private Result run(String operation) throws Exception {
        if(!Arrays.asList("state","start","stop","wake-on","wake-off","sync").contains(operation)&&!operation.matches("interval [0-9]{2,5}"))throw new IllegalArgumentException();
        String command=CONTROL+operation;
        if(operation.equals("state"))command="[ \"$(id -u)\" = 0 ] || exit 1; if [ -f /data/adb/ddns-go/control.sh ]; then "+command+"; else echo setup=missing; fi";
        RootShell.Result result=RootShell.run(command,55);
        return new Result(result.code,result.output);
    }
    private void load(String operation){
        if(busy||isFinishing())return;
        if(DeploymentService.ACTIVE.get()){
            serviceSwitch.setEnabled(false);wakeSwitch.setEnabled(false);checkButton.setEnabled(false);refreshButton.setEnabled(false);syncButton.setEnabled(false);intervalButton.setEnabled(false);
            status.setText(R.string.deploy_installing);return;
        }
        setBusy(true);
        worker.execute(()->{
            try{
                BackendRuntime.ensureCurrent(this);
                Result action=operation==null?null:run(operation);
                if("start".equals(operation))Thread.sleep(650);
                Result r=run("state");
                if(r.code==0&&r.output.contains("setup=missing")){
                    runOnUiThread(()->{if(isFinishing())return;controlsSupported=false;backendRunning=false;setBusy(false);status.setText(R.string.deploy_not_installed);subtitle.setText(R.string.deploy_first_step);address.setText("—");notice.setText(R.string.deploy_credentials_note);serviceSwitch.setEnabled(false);wakeSwitch.setEnabled(false);checkButton.setEnabled(false);});return;
                }
                if(r.code!=0||!r.output.contains("engine=ddns-go"))throw new Exception("root/backend unavailable");
                runOnUiThread(()->{if(isFinishing())return;setBusy(false);render(r.output);if(action!=null){int message=action.code!=0?R.string.action_failed:"sync".equals(operation)?R.string.sync_triggered:R.string.applied;Toast.makeText(this,getString(message),Toast.LENGTH_LONG).show();}});
            }catch(Exception e){String reason=e.getMessage();android.util.Log.w("DDNS-Control","operation="+(operation==null?"state":operation)+"; error="+(reason!=null&&reason.matches("[A-Z_]{3,40}")?reason:e.getClass().getSimpleName()));runOnUiThread(()->{if(isFinishing())return;controlsSupported=false;backendRunning=false;setBusy(false);status.setText(getString(R.string.unavailable));subtitle.setText(getString(R.string.root_hint));notice.setText(getString(R.string.root_notice));serviceSwitch.setEnabled(false);wakeSwitch.setEnabled(false);checkButton.setEnabled(false);});}
        });
    }
    private void render(String output){
        String[] sections=output.split("---LOG---\\n",2);Map<String,String> values=new HashMap<>();
        for(String line:sections[0].split("\\n")){int i=line.indexOf('=');if(i>0)values.put(line.substring(0,i),line.substring(i+1));}
        boolean enabled="1".equals(values.get("enabled")), running="1".equals(values.get("running")), wake="1".equals(values.get("wake_enabled")), held="1".equals(values.get("wake_held"));
        controlsSupported="2".equals(values.get("control_api"));backendRunning=running;
        try{int seconds=Integer.parseInt(values.getOrDefault("interval_seconds","300"));if(seconds>=60&&seconds<=86400&&seconds%60==0)intervalSeconds=seconds;}catch(NumberFormatException ignored){}
        intervalHint.setText(controlsSupported?getString(R.string.interval_value,intervalSeconds/60):getString(R.string.controls_update_needed));
        syncButton.setEnabled(!busy&&controlsSupported&&running);intervalButton.setEnabled(!busy&&controlsSupported);
        binding=true;serviceSwitch.setChecked(enabled);wakeSwitch.setChecked(wake);binding=false;
        engineVersion.setText(values.getOrDefault("engine","ddns-go"));
        status.setText(running?getString(R.string.running):enabled?getString(R.string.not_running):getString(R.string.paused));
        subtitle.setText(running?(held?getString(R.string.running_awake,intervalSeconds/60):getString(R.string.running_sleep,intervalSeconds/60)):(enabled?getString(R.string.restart_hint):getString(R.string.paused_hint)));
        wakeHint.setText(!wake?getString(R.string.wake_off):held?getString(R.string.wake_active):getString(R.string.wake_pending));
        String ip=values.getOrDefault("address","");
        address.setText(ip.isEmpty()?getString(R.string.waiting_ipv6):ip);
        synced.setText(ip.isEmpty()?getString(R.string.no_ipv6):getString(R.string.ipv6_hint));
        logs=sections.length>1?sections[1].trim():getString(R.string.no_logs);
        String[] lines=logs.split("\\n");
        String last=lines.length==0?"":lines[lines.length-1];
        if(last.contains("ERROR")||last.contains("失败")||last.contains("异常")){notice.setTextColor(Color.rgb(160,94,22));notice.setText(getString(R.string.log_warning));}
        else {notice.setTextColor(MUTED);notice.setText(getString(R.string.local_only));}
    }
    private void editInterval(){
        final EditText input=new EditText(this);input.setInputType(InputType.TYPE_CLASS_NUMBER);input.setSingleLine(true);input.setText(String.valueOf(intervalSeconds/60));input.selectAll();
        LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);box.setPadding(dp(22),dp(8),dp(22),0);
        add(box,text(getString(R.string.interval_help),13,MUTED,false),0,10);box.addView(input);
        AlertDialog dialog=new AlertDialog.Builder(this).setTitle(R.string.check_interval).setView(box).setNegativeButton(R.string.cancel,null).setPositiveButton(R.string.save,null).create();
        dialog.setOnShowListener(ignored->dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v->{
            try{
                String raw=input.getText().toString().trim();if(!raw.matches("[0-9]{1,4}"))throw new NumberFormatException();
                int minutes=Integer.parseInt(raw);if(minutes<1||minutes>1440)throw new NumberFormatException();
                dialog.dismiss();load("interval "+(minutes*60));
            }catch(NumberFormatException error){input.setError(getString(R.string.interval_invalid));}
        }));dialog.show();
    }
    private void showLogs(){TextView t=text(logs,12,INK,false);t.setTypeface(Typeface.MONOSPACE);t.setTextIsSelectable(true);t.setPadding(dp(18),dp(12),dp(18),dp(12));ScrollView s=new ScrollView(this);s.addView(t);new AlertDialog.Builder(this).setTitle(getString(R.string.recent_logs)).setView(s).setPositiveButton(getString(R.string.close),null).show();}
    protected void onResume(){super.onResume();resumed=true;handler.postDelayed(poll,15000);if(status!=null)load(null);}
    protected void onPause(){super.onPause();resumed=false;handler.removeCallbacks(poll);}
    protected void onDestroy(){super.onDestroy();worker.shutdown();handler.removeCallbacksAndMessages(null);}
}
