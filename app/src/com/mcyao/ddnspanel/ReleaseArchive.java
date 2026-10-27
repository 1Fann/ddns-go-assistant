package com.mcyao.ddnspanel;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.zip.GZIPInputStream;

/** Reads only the expected regular ELF member. Never extracts archive paths. */
public final class ReleaseArchive {
    private static final long LIMIT=128L*1024*1024;
    public static void verify(File archive,String expected) throws Exception {
        if(!expected.matches("[a-fA-F0-9]{64}"))throw new IOException("CHECKSUM_MISSING");
        MessageDigest md=MessageDigest.getInstance("SHA-256");
        try(InputStream in=new FileInputStream(archive)){byte[] b=new byte[16384];int n;while((n=in.read(b))!=-1)md.update(b,0,n);}
        StringBuilder hex=new StringBuilder();for(byte b:md.digest())hex.append(String.format("%02x",b&255));
        if(!hex.toString().equalsIgnoreCase(expected))throw new IOException("CHECKSUM_MISMATCH");
    }
    private static boolean block(InputStream in,byte[] b) throws IOException {
        int offset=0,n;while(offset<b.length){n=in.read(b,offset,b.length-offset);if(n<0){if(offset==0)return false;throw new EOFException("ARCHIVE_INVALID");}offset+=n;}return true;
    }
    private static long octal(byte[] b,int offset,int length) throws IOException {
        String s=new String(b,offset,length,StandardCharsets.US_ASCII).replace("\0","").trim();
        if(!s.matches("[0-7]+"))throw new IOException("ARCHIVE_INVALID");
        try{return Long.parseLong(s,8);}catch(NumberFormatException e){throw new IOException("ARCHIVE_INVALID");}
    }
    private static String field(byte[] b,int offset,int length){int end=offset;while(end<offset+length&&b[end]!=0)end++;return new String(b,offset,end-offset,StandardCharsets.US_ASCII);}
    public static void extract(File archive,File output) throws IOException {
        boolean found=false;long expanded=0;
        try(InputStream in=new GZIPInputStream(new FileInputStream(archive))){
            byte[] header=new byte[512],buf=new byte[16384];
            while(block(in,header)){
                boolean zero=true;for(byte b:header)if(b!=0){zero=false;break;}if(zero)break;
                long checksum=0;for(int i=0;i<512;i++)checksum+=(i>=148&&i<156)?32:header[i]&255;
                if(checksum!=octal(header,148,8))throw new IOException("ARCHIVE_INVALID");
                String name=field(header,0,100),prefix=field(header,345,155);
                if(!prefix.isEmpty())name=prefix+"/"+name;
                long size=octal(header,124,12);expanded+=512+size;
                if(size<0||expanded>LIMIT)throw new IOException("ARCHIVE_TOO_LARGE");
                boolean target=name.equals("ddns-go")||name.equals("./ddns-go");
                if(target&&(found||(header[156]!=0&&header[156]!='0')))throw new IOException("ARCHIVE_INVALID");
                OutputStream out=target?new FileOutputStream(output):null;
                try{long left=size;while(left>0){int n=in.read(buf,0,(int)Math.min(buf.length,left));if(n<0)throw new EOFException("ARCHIVE_INVALID");if(out!=null)out.write(buf,0,n);left-=n;}}
                finally{if(out!=null)out.close();}
                if(target)found=true;
                long padding=(512-size%512)%512;while(padding>0){int n=in.read(buf,0,(int)padding);if(n<0)throw new EOFException("ARCHIVE_INVALID");padding-=n;}
            }
        }catch(IOException e){output.delete();throw e;}
        if(!found){output.delete();throw new IOException("ARCHIVE_INVALID");}
        try(InputStream in=new FileInputStream(output)){
            byte[] elf=new byte[20];if(!block(in,elf)||elf[0]!=127||elf[1]!='E'||elf[2]!='L'||elf[3]!='F'||elf[4]!=2||elf[5]!=1||(elf[18]&255)!=183||elf[19]!=0)throw new IOException("ARCHITECTURE_UNSUPPORTED");
        }catch(IOException e){output.delete();throw e;}
    }
}
