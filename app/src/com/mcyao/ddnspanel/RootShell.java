package com.mcyao.ddnspanel;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

/** Bounded output, drained while the child runs so a full pipe cannot deadlock it. */
final class RootShell {
 static String busybox()throws Exception{
  String command="for p in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do if [ -x \"$p\" ]; then echo \"$p\"; exit 0; fi; done; exit 20";
  String path=run(command,8).output.trim();
  if(!path.matches("/data/adb/(magisk|ksu/bin|ap/bin)/busybox"))throw new IOException("需要 Root 管理器提供 BusyBox；请检查 Magisk、KernelSU 或 APatch 安装");
  return path;
 }

    static final String BASE="/data/adb/ddns-go";
    static final class Result {
        final int code; final String output;
        Result(int code,String output){this.code=code;this.output=output;}
    }
    static String quote(String s){return "'"+s.replace("'","'\\''")+"'";}
    static Result run(String command,int timeout) throws Exception {
        Process p=new ProcessBuilder("su","-M","-c",command).redirectErrorStream(true).start();
        p.getOutputStream().close();
        ByteArrayOutputStream out=new ByteArrayOutputStream();
        Thread reader=new Thread(()->{
            try(InputStream in=p.getInputStream()){
                byte[] b=new byte[4096];int n;
                while((n=in.read(b))!=-1){synchronized(out){int remaining=32768-out.size();if(remaining>0)out.write(b,0,Math.min(n,remaining));}}
            }catch(IOException ignored){}
        },"root-output");
        reader.setDaemon(true);reader.start();
        if(!p.waitFor(timeout,TimeUnit.SECONDS)){p.destroy();throw new IOException("ROOT_TIMEOUT");}
        reader.join(2000);
        synchronized(out){return new Result(p.exitValue(),new String(out.toByteArray(),StandardCharsets.UTF_8));}
    }
}
