//every 30 seconds,take a picture
// we render the images into a random style/dream, then we cycle through those images. 
//save a list of images in data/processed, then have our code randomly grab and render it
import processing.video.*;
import http.requests.*;
import java.nio.file.Paths;
import java.nio.file.Path;
import java.util.Arrays;

import java.nio.file.Files;
import java.util.Random;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.http.message.BasicNameValuePair;
import java.io.FileOutputStream;
import java.util.Map;
import java.lang.*;



PImage cam_image;
FileBody camFileBody;
HttpResponse response;
Capture cam;
String url = "http://24.218.219.39:8888/api/v1.2/post-query";
//String url = "http://convert.somatic.io/api/v1.2/post-query";
String path;
PImage target_image;
PImage source_image;
PImage jitter_image;
PImage m;
float rot = 360.0;
PGraphics pgTaiji;
PImage piBuffer;
PImage transition_image;
int counter= 1;
int our_height = 1080;
int our_width = 1920;
int processed = 0;
int switch_count = 0;
int threads_processing = 0;
int lastTime = 0;
int direction = 0;
float lerp_rate = 0;
String[] dream_ids = {"pE4A9yk0","7ZxJpMk9","DkMle5Eg"};
String[] style_ids = {"LnL71DkK","9kgYo1Zp","Bka9oBkM","2kRl49ZW","MZJNYmZY","LnL7oLkK","8k8aLmnM","yE72lBZm"};
String[] model_ids = new  String[dream_ids.length + style_ids.length];
String cam_path;
PImage[] model_images = new PImage[model_ids.length];
int first_step = 0;
Model[] models = new Model[model_ids.length];
PGraphics rotatingTaiji(int a,float xstep,float ystep) {
  PGraphics taiji = createGraphics(width, height);
  taiji.beginDraw();
  taiji.translate((width-height)/2, 0);
  taiji.background(230,0);
  taiji.fill(255);
  taiji.arc(xstep,ystep,a,a,PI/2,PI*3/2);
  //draw right black arc
  taiji.fill(0);
  taiji.arc(xstep,ystep,a,a,-PI/2,PI/2);
  taiji.noStroke();
  //draw down big arc
  taiji.arc(a/2,a*3/4,a/2,a/2,PI/2,PI*3/2);
  //draw up big arc
  taiji.fill(255);
  taiji.arc(a/2,a/4,a/2,a/2,-PI/2,PI/2);
  //draw down small arc
  taiji.ellipse(a/2,a*3/4,a/10,a/10);
  //draw up small arc
  taiji.fill(0);
  taiji.ellipse(a/2,a/4,a/10,a/10);
  taiji.endDraw();
  return taiji;
}
class Model implements Runnable {
  private Thread t;
  PImage image;
  String model_id;
  int retry_count = 0;
  public Model(String mid) {
    model_id = mid;
  }
  public void start () {
    t = new Thread (this, model_id);
    t.start ();
  }
  public void run(){
    println("RUN");
      int rnd = new Random().nextInt(model_ids.length);
      model_id = model_ids[rnd];
      String field_name = null;
      if(Arrays.asList(dream_ids).contains(model_id)){
        field_name = "--image";
        
      }else{
        field_name = "--input";
      }
      println("get_model_id:"+model_id);
      DefaultHttpClient client = new DefaultHttpClient();
      HttpPost post = new HttpPost(url);

      try{

      MultipartEntity entity = new MultipartEntity();
      BasicNameValuePair nvp = new BasicNameValuePair("api_key",System.getenv("SOMATIC_API_KEY"));
      entity.addPart(nvp.getName(), new StringBody(nvp.getValue()));
      File cam_file = new File(cam_path);
      println(cam_file.length());
      entity.addPart(field_name, new FileBody(new File(cam_path)));
      BasicNameValuePair nvp2 = new BasicNameValuePair("id",model_id);
      entity.addPart(nvp2.getName(), new StringBody(nvp2.getValue()));
      post.setEntity(entity);
      HttpResponse response = client.execute(post);

      String processed_path = path+"/processed_"+model_id+".png";
      InputStream instream = response.getEntity().getContent();
      FileOutputStream output = new FileOutputStream(processed_path);
      int bufferSize = 1024;
      byte[] buffer = new byte[bufferSize];
      int len = 0;
      while ((len = instream.read(buffer)) != -1) {
          output.write(buffer, 0, len);
      }
      output.close();

      PImage tmp = loadImage(processed_path);
      if(tmp.width != -1 && tmp.height != -1){
        println("style fine");
        image = tmp.copy();
        if(target_image == null){
          target_image= tmp.copy();
        }
      }else{
        println("style not fine");
      }
      processed += 1;
      counter +=1 ;
      threads_processing -= 1;
      println("processed from somatic");
      }catch (Exception e){
        //retry_count += 1 ;
        println("shit");
        e.printStackTrace();
      }
    }
}

void get_images(){

}

void setup() {
  path = dataPath("");
  File dir = new File(path+"/processed/");
  dir.mkdirs();
  //size(1080,1080,P2D);
  fullScreen(P2D);
  println("key:"+System.getenv("SOMATIC_API_KEY"));
  cam = new Capture(this, 1280,720, 30);
  cam.start();
   if(cam.available()) {
    cam.read();
   }
  transition_image = createImage(width,height, RGB);
  cam_image = cam;
  source_image = cam.copy();
  if(source_image.height !=height || source_image.width !=width){
    source_image.resize(width,height);
  }
  smooth();
  pgTaiji = rotatingTaiji(height, height/2, height/2);
  piBuffer = pgTaiji.get();
  m = pgTaiji.get();
}
void draw() {
  background(225);
  if(cam.available()) {
    cam.read();
  }
  if( millis() >= 5000 && target_image == null  ){
    image(cam,0,0);
    source_image = cam.copy();
  if(source_image.height !=height || source_image.width !=width){
    source_image.resize(width,height);
  }
    cam_image = cam;
    if(first_step == 0){
      cam_path = path +"/cam.png";
      cam.save(cam_path);
      get_images();
      first_step = 1;

    }
  }else if(millis()  < 5000  ){
    println("only firset 5");
    image(cam,0,0);

  }else if( millis() - lastTime >= 60000){
  //}else if( millis() - lastTime >= 120000){
    lastTime = millis();
    cam_image = cam;
    cam_path = path +"/cam.png";
    cam.save(cam_path);
    get_images();
    println("2 minutes passed");

  }else if (source_image != null && target_image != null){

  pgTaiji.pushMatrix();
  pgTaiji.imageMode(CENTER);
  pgTaiji.beginDraw();
  pgTaiji.translate(pgTaiji.width/2, pgTaiji.height/2);
  pgTaiji.rotate(radians(rot));
  pgTaiji.image(piBuffer, 0, 0);
  pgTaiji.endDraw();
  pgTaiji.popMatrix();

  rot+=1;
  if (rot < 0) rot = 360;

  m = pgTaiji.get();
  image(m,0,0);
    target_image.loadPixels();
    source_image.loadPixels();
    transition_image.updatePixels();
    if(target_image.height != height || target_image.width !=  width){
      target_image.resize(width,height);
    }

    if(source_image.height !=height || source_image.width !=width){
      source_image.resize(width,height);
    }
    if(transition_image.height != height || transition_image.width != width){
      transition_image.resize(width,height);
    }



  //  image(jitter_image, 0, 0, 200, 200);

  loadPixels();
  for (int y = 0; y < target_image.height; y++) {
    for (int x = 0; x < target_image.width; x++) {
      int loc = x + y*target_image.width;
      if (lerp_rate<=0.5) {
        color new_color = lerpColor(source_image.pixels[loc], m.pixels[loc], lerp_rate*2);
        transition_image.pixels[loc] = new_color;
      }
      else {
        color new_color = lerpColor(target_image.pixels[loc], m.pixels[loc], 2-2*lerp_rate);
        transition_image.pixels[loc] = new_color;
      }
    }
  }
  transition_image.updatePixels();
  lerp_rate += 0.01;
  lerp_rate = constrain(lerp_rate, 0,1);
  float jitter;
  if (lerp_rate < 0.5) {
    jitter = map(lerp_rate, 0, 0.5, 0, 1);
  } else {
    jitter = map(lerp_rate, 0.5, 1, 1, 0);
  }


  image(transition_image, 0,0);
  text("Jitter: " + jitter, 10,10);
  if (jitter== 1 || jitter == 0){
    lerp_rate = 0;
    cam.read();
    int model_counter = counter%(model_images.length);
    PImage next_image = null;
    PImage current_image = model_images[model_counter];
    while(next_image == null){
      model_counter = counter%(model_images.length);
      println("XXXXXXXXXXXX");
      if (model_counter  < model_images.length){
        if(models[model_counter] != null && models[model_counter].image != null){
          next_image =  models[model_counter].image;
          counter += 1;
        }
      }else{
        counter = 0;
        if(models[0] != null && models[model_counter].image != null){
          next_image = models[model_counter].image;
        }else{
          counter +=1 ;
        }
      }
    }
    println("end while");

      source_image = target_image.copy();
      target_image = next_image.copy(); //change this to read from data/processed and load a random image

  }

  }

}