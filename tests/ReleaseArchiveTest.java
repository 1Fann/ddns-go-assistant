import com.mcyao.ddnspanel.ReleaseArchive;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.*;
import java.util.zip.GZIPOutputStream;

public class ReleaseArchiveTest {
    static byte[] elf(){byte[] b=new byte[32];b[0]=127;b[1]='E';b[2]='L';b[3]='F';b[4]=2;b[5]=1;b[18]=(byte)183;return b;}
    static byte[] member(String name,byte type,byte[] body) throws Exception {
        byte[] h=new byte[512];byte[] n=name.getBytes(StandardCharsets.US_ASCII);System.arraycopy(n,0,h,0,n.length);
        byte[] size=String.format("%011o",body.length).getBytes(StandardCharsets.US_ASCII);System.arraycopy(size,0,h,124,size.length);h[156]=type;
        Arrays.fill(h,148,156,(byte)32);int sum=0;for(byte b:h)sum+=b&255;byte[] check=String.format("%06o\0 ",sum).getBytes(StandardCharsets.US_ASCII);System.arraycopy(check,0,h,148,8);
        ByteArrayOutputStream out=new ByteArrayOutputStream();out.write(h);out.write(body);out.write(new byte[(512-body.length%512)%512]);return out.toByteArray();
    }
    static File archive(Path dir,byte[]...members) throws Exception {
        File f=dir.resolve("input.tar.gz").toFile();try(OutputStream out=new GZIPOutputStream(new FileOutputStream(f))){for(byte[] m:members)out.write(m);out.write(new byte[1024]);}return f;
    }
    static void reject(File in,File out) throws Exception {try{ReleaseArchive.extract(in,out);throw new AssertionError("Malformed archive accepted");}catch(IOException expected){if(out.exists())throw new AssertionError("Partial binary retained");}}
    public static void main(String[] args) throws Exception {
        Path dir=Files.createTempDirectory("ddns-archive-test-");File out=dir.resolve("ddns-go").toFile();
        try{
            File good=archive(dir,member("LICENSE",(byte)'0',new byte[1]),member("ddns-go",(byte)'0',elf()));
            ReleaseArchive.extract(good,out);if(out.length()!=32)throw new AssertionError();
            StringBuilder hash=new StringBuilder();for(byte b:MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(good.toPath())))hash.append(String.format("%02x",b&255));
            ReleaseArchive.verify(good,hash.toString());
            try{ReleaseArchive.verify(good,String.join("",Collections.nCopies(64,"0")));throw new AssertionError("Bad checksum accepted");}catch(IOException expected){}
            reject(archive(dir,member("../ddns-go",(byte)'0',elf())),out);
            reject(archive(dir,member("ddns-go",(byte)'2',new byte[0])),out);
            reject(archive(dir,member("ddns-go",(byte)'0',elf()),member("ddns-go",(byte)'0',elf())),out);
            byte[] wrong=elf();wrong[18]=62;reject(archive(dir,member("ddns-go",(byte)'0',wrong)),out);
            byte[] corrupt=member("ddns-go",(byte)'0',elf());corrupt[10]=33;reject(archive(dir,corrupt),out);
            System.out.println("Archive tests passed: checksum, valid ELF, traversal, symlink, duplicate, wrong architecture, bad header.");
        }finally{Files.deleteIfExists(out.toPath());Files.deleteIfExists(dir.resolve("input.tar.gz"));Files.deleteIfExists(dir);}
    }
}
