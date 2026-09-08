import java.net.URI;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.Path;

public class HdfsDemo {

    public static void main(String[] args) throws Exception {

        String uri = "hdfs://namenode:8020";
        Configuration conf = new Configuration();
        FileSystem fs = FileSystem.get(URI.create(uri), conf);
        Path file = new Path("/user/student/quangle.txt");

        FSDataOutputStream out = fs.create(file);
        out.writeBytes("On the top of the Crumpetty Tree\n");
        out.writeBytes("The Quangle Wangle sat\n");
        out.close();

        System.out.println("Wrote file: " + file);

        FSDataInputStream in = fs.open(file);
        byte[] buffer = new byte[32];
        in.read(buffer);
        System.out.println("From start : " + new String(buffer).trim());

        in.seek(33);
        byte[] buf2 = new byte[32];
        in.read(buf2);
        System.out.println("After seek : " + new String(buf2).trim());
        in.close();

        FileStatus st = fs.getFileStatus(file);
        System.out.println("Length     : " + st.getLen() + " bytes");
        System.out.println("Replication: " + st.getReplication());

        System.out.println("--- listStatus /user/student ---");
        for (FileStatus s : fs.listStatus(new Path("/user/student"))) {
            System.out.println("  " + s.getPath().getName());
        }

        System.out.println("--- globStatus *.txt ---");
        for (FileStatus s : fs.globStatus(new Path("/user/student/*.txt"))) {
            System.out.println("  " + s.getPath().getName());
        }

        fs.close();
    }
}
