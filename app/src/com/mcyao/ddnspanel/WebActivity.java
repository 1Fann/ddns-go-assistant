package com.mcyao.ddnspanel;
import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.net.Uri;
import android.view.View;
import android.view.WindowManager;
import android.webkit.*;
import android.widget.*;
import java.io.ByteArrayInputStream;

/** Displays the unmodified official local ddns-go UI. No JavaScript/native bridge. */
public final class WebActivity extends Activity {
    private WebView web;
    protected void onCreate(Bundle state){
        super.onCreate(state);
        // Protect locally entered passwords and API-token fields from screenshots.
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
        getWindow().setStatusBarColor(Color.rgb(243,247,251));
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        LinearLayout page=new LinearLayout(this);page.setOrientation(LinearLayout.VERTICAL);
        LinearLayout bar=new LinearLayout(this);bar.setPadding(12,4,12,4);bar.setBackgroundColor(Color.rgb(243,247,251));
        Button back=new Button(this);back.setText(getString(R.string.back));back.setOnClickListener(v->finish());
        TextView title=new TextView(this);title.setText(getString(R.string.web_title));title.setTextColor(Color.rgb(21,43,68));title.setTextSize(15);title.setGravity(17);
        Button refresh=new Button(this);refresh.setText(getString(R.string.refresh));refresh.setOnClickListener(v->web.reload());
        bar.addView(back);bar.addView(title,new LinearLayout.LayoutParams(0,-1,1));bar.addView(refresh);page.addView(bar);
        web=new WebView(this);WebSettings settings=web.getSettings();
        settings.setJavaScriptEnabled(true);settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(false);settings.setAllowContentAccess(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        CookieManager.getInstance().setAcceptCookie(true);CookieManager.getInstance().setAcceptThirdPartyCookies(web,false);
        web.setWebViewClient(new WebViewClient(){
            private boolean local(Uri u){return "http".equals(u.getScheme())&&("127.0.0.1".equals(u.getHost())||"localhost".equals(u.getHost()))&&u.getPort()==9876;}
            public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){if(local(r.getUrl()))return false;Toast.makeText(WebActivity.this,getString(R.string.local_window_only),Toast.LENGTH_SHORT).show();return true;}
            public WebResourceResponse shouldInterceptRequest(WebView v,WebResourceRequest r){if(local(r.getUrl()))return null;return new WebResourceResponse("text/plain","UTF-8",new ByteArrayInputStream(new byte[0]));}
        });
        page.addView(web,new LinearLayout.LayoutParams(-1,0,1));setContentView(page);
        if(state!=null)web.restoreState(state);else web.loadUrl("http://127.0.0.1:9876/login");
    }
    protected void onSaveInstanceState(Bundle state){super.onSaveInstanceState(state);web.saveState(state);}
    public void onBackPressed(){if(web.canGoBack())web.goBack();else finish();}
    protected void onDestroy(){if(web!=null){web.stopLoading();web.destroy();}super.onDestroy();}
}
