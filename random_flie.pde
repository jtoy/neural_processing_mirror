import java.util.Random;
String path;

void get_images(String dir) {
  println(dir);
}


void setup() {
  path = dataPath("");
  File dir = new File(path+"/processed/");
  dir.mkdirs();
}

void draw() {
  File folder = new File(path+"/processed/");
  File[] listOfFiles = folder.listFiles();
  int file_count = listOfFiles.length;
  Random random = new Random();
  int index = random.nextInt(file_count);
  println(listOfFiles[index]);
}