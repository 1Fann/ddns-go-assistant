package com.mcyao.ddnspanel;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.*;

public final class DeploymentActivity extends Activity {
    private final Handler handler=new Handler();
    private RadioButton recommended,latest;
    private Button install,manage;
    private TextView state,detail;
    private ProgressBar progress;
    private boolean visible;
    private final Runnable poll=new Runnable(){public void run(){if(visible){render();handler.postDelayed(this,500);}}};
    protected void onCreate(Bundle saved){
        super.onCreate(saved);
        getWindow().setStatusBarColor(Color.rgb(243,247,251));
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        ScrollView scroll=new ScrollView(this);scroll.setBackgroundColor(Color.rgb(243,247,251));
        LinearLayout page=new LinearLayout(this);page.setOrientation(LinearLayout.VERTICAL);int pad=dp(22);page.setPadding(pad,pad,pad,pad);scroll.addView(page);
        Button back=new Button(this);back.setText(R.string.back);back.setOnClickListener(v->finish());page.addView(back);
        TextView title=label(getString(R.string.deploy_title),25);page.addView(title);
        page.addView(label(getString(R.string.deploy_intro),15));
        RadioGroup choices=new RadioGroup(this);recommended=new RadioButton(this);recommended.setId(View.generateViewId());recommended.setText(getString(R.string.deploy_recommended,DeploymentService.RECOMMENDED));
        latest=new RadioButton(this);latest.setId(View.generateViewId());latest.setText(R.string.deploy_latest);choices.addView(recommended);choices.addView(latest);recommended.setChecked(true);page.addView(choices);
        page.addView(label(getString(R.string.deploy_versions_note),13));
        install=new Button(this);install.setText(R.string.deploy_action);page.addView(install);
        install.setOnClickListener(v->{if(DeploymentService.ACTIVE.get())return;startForegroundService(new Intent(this,DeploymentService.class).putExtra("latest",latest.isChecked()));install.setEnabled(false);});
        progress=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);page.addView(progress,new LinearLayout.LayoutParams(-1,dp(6)));
        state=label("",18);detail=label("",14);page.addView(state);page.addView(detail);
        manage=new Button(this);manage.setText(R.string.open_management);manage.setOnClickListener(v->startActivity(new Intent(this,WebActivity.class)));page.addView(manage);
        page.addView(label(getString(R.string.deploy_credentials_note),14));
        setContentView(scroll);render();
    }
    private int dp(int n){return Math.round(n*getResources().getDisplayMetrics().density);}
    private TextView label(String s,int size){TextView t=new TextView(this);t.setText(s);t.setTextSize(size);t.setTextColor(Color.rgb(21,43,68));t.setPadding(0,dp(12),0,dp(12));return t;}
    private void render(){
        boolean active=DeploymentService.ACTIVE.get();install.setEnabled(!active);recommended.setEnabled(!active);latest.setEnabled(!active);
        progress.setVisibility(active?View.VISIBLE:View.GONE);progress.setIndeterminate(DeploymentService.percent<0);if(DeploymentService.percent>=0)progress.setProgress(DeploymentService.percent);
        state.setText(DeploymentService.message==0?getString(R.string.deploy_ready):getString(DeploymentService.message));
        String info=DeploymentService.version;
        if(!DeploymentService.error.isEmpty())info+="\n"+getString(errorText(DeploymentService.error))+"\n"+DeploymentService.error;
        detail.setText(info);manage.setVisibility(DeploymentService.success&&!DeploymentService.paused?View.VISIBLE:View.GONE);
    }
    private int errorText(String code){
        switch(code){
            case "ROOT_REQUIRED":case "ROOT_TIMEOUT":return R.string.deploy_error_root;
            case "EXISTING_INSTALLATION":return R.string.deploy_error_existing;
            case "ENVIRONMENT_UNSUPPORTED":case "ARCHITECTURE_UNSUPPORTED":return R.string.deploy_error_environment;
            case "CHECKSUM_MISMATCH":case "CHECKSUM_MISSING":case "ARCHIVE_INVALID":case "ARCHIVE_TOO_LARGE":return R.string.deploy_error_checksum;
            case "GITHUB_RATE_LIMIT":return R.string.deploy_error_rate;
            case "INSTALL_ROLLED_BACK":return R.string.deploy_error_rollback;
            case "RECOVERY_REQUIRED":return R.string.deploy_error_recovery;
            case "INSTALL_FAILED":return R.string.deploy_error_install;
            case "RELEASE_UNSUPPORTED":return R.string.deploy_error_release;
            default:return R.string.deploy_error_network;
        }
    }
    protected void onResume(){super.onResume();visible=true;handler.post(poll);}
    protected void onPause(){super.onPause();visible=false;handler.removeCallbacks(poll);}
}
