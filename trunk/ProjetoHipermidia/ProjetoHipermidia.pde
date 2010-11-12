/**	NyARToolkit for proce55ing/0.3.0
	(c)2008-2010 nyatla
	airmail(at)ebony.plala.or.jp

  example modified to demonstrate NyARMultiBoard + NyARMultiBoardMarker by
  Charl P. Botha <http://cpbotha.net/>
*/
 
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.opengl.*;
import javax.media.opengl.*;
import saito.objloader.*;
import objimp.*;

Capture cam;
NyARMultiBoard nya;
ObjImpScene scene;
//OBJModel model;
OBJModel model2;
PFont font;
int variacao = 0;
float angulo1, angulo2 = 0;

String angle2text(float a)
{
  int i=(int)degrees(a);
  i=(i>0?i:i+360);
  return (i<100?"  ":i<10?" ":"")+Integer.toString(i);
}
String trans2text(float i)
{
  return (i<100?"  ":i<10?" ":"")+Integer.toString((int)i);
}

void setup() {
  // trecho para funcionamento no OSX
  try {
    quicktime.QTSession.open();
  } catch (quicktime.QTException qte) {
    qte.printStackTrace();
  }
  
  size(640,480,OPENGL);
   hint( ENABLE_OPENGL_4X_SMOOTH );
  smooth();

  frameRate( 60 );
  // making an object called "model" that is a new instance of OBJModel
  //model = new OBJModel(this, "VW-new-beetle.obj", "relative", QUADS);
  //model.scale(8);
  scene = new ObjImpScene( this );
  scene.load( dataPath("house_obj.obj"), 5 );
  //model2 = new OBJModel(this, "VW-new-beetle.obj", "relative", QUADS);
  //model2.scale(8);
  //colorMode(RGB, 100);
  font=createFont("FFScala", 32);
  // I'm using the GSVideo capture stack
  cam=new Capture(this,width,height);
  // array of pattern file names, these have to be in NyARMultiTest/data
  String[] patts = {"patt.hiro", "patt.kanji"};
  // array of corresponding widths in mm
  double[] widths = {80,80};
  // initialise the NyARMultiBoard
  nya=new NyARMultiBoard(this,width,height,"camera_para.dat",patts,widths);
  print(nya.VERSION);

  nya.gsThreshold=120;//(0<n<255) default=110
  nya.cfThreshold=0.4;//(0.0<n<1.0) default=0.4

}

void drawMarkerPos(int[][] pos2d)
{
  textFont(font,10.0);
  stroke(100,0,0);
  fill(100,0,0);
  
  // draw ellipses at outside corners of marker
  for(int i=0;i<4;i++){
    ellipse(pos2d[i][0], pos2d[i][1],5,5);
  }
  
  fill(0,0,0);
  for(int i=0;i<4;i++){
    text("("+pos2d[i][0]+","+pos2d[i][1]+")",pos2d[i][0],pos2d[i][1]);
  }
}

// val is 0 or 1. 0 = directional light, 1 = point light
void setupLight( GL g, float[] pos, float val )
{
  float[] light_emissive = { 0.0f, 0.0f, 0.0f, 1 };
  float[] light_ambient = { 7f, 7f, 7f, 1 };
  float[] light_diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
  float[] light_specular = { 1.0f, 1.0f, 1.0f, 1.0f };  
  float[] light_position = { pos[0], pos[1], pos[2], val };  

  g.glLightfv ( GL.GL_LIGHT1, GL.GL_AMBIENT, light_ambient, 0 );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_DIFFUSE, light_diffuse, 0 );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_SPECULAR, light_specular, 0 );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_POSITION, light_position, 0 );  
  g.glEnable( GL.GL_LIGHT1 );
  g.glEnable( GL.GL_LIGHTING );
  
  g.glEnable( GL.GL_COLOR_MATERIAL );
}  

void draw() {
  //lights();
  //directionalLight(51, 102, 126, -1, 0, 0);
  
  GL _gl = ((PGraphicsOpenGL)g).beginGL();
  setupLight( _gl, new float[]{0, 15, 0}, 1 );
  ((PGraphicsOpenGL)g).endGL();
  
  //scale( 0.2, -0.2, 0.2 );
  //translate( 0, -3000, -3000 );
  //scene.draw();
  if (cam.available() !=true) {
    return;
  }

  background(255);
  cam.read();
  hint(DISABLE_DEPTH_TEST);
  image(cam,0,0);
  background(cam);
  hint(ENABLE_DEPTH_TEST);

  if (nya.detect(cam))
  {
        
    hint(DISABLE_DEPTH_TEST);
    for (int i=0; i < nya.markers.length; i++)
    {
      if (nya.markers[i].detected)
      {
        textFont(font,25.0);
        fill((int)((1.0-nya.markers[i].confidence)*100),(int)(nya.markers[i].confidence*100),0);
        text((int)(nya.markers[i].confidence*100)+"%",width-60,height-20);
        pushMatrix();
        textFont(font,10.0);
        fill(0,100,0,80);
        translate((nya.markers[i].pos2d[0][0]+nya.markers[i].pos2d[1][0]+nya.markers[i].pos2d[2][0]+nya.markers[i].pos2d[3][0])/4+50,(nya.markers[i].pos2d[0][1]+nya.markers[i].pos2d[1][1]+nya.markers[i].pos2d[2][1]+nya.markers[i].pos2d[3][1])/4+50);
        text("TRANS "+trans2text(nya.markers[i].trans.x)+","+trans2text(nya.markers[i].trans.y)+","+trans2text(nya.markers[i].trans.z),0,0);
        text("ANGLE "+angle2text(nya.markers[i].angle.x)+","+angle2text(nya.markers[i].angle.y)+","+angle2text(nya.markers[i].angle.z),0,15);
        popMatrix();  
        drawMarkerPos(nya.markers[i].pos2d);
      }
    }
    
    hint(ENABLE_DEPTH_TEST);
    
    PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
    for (int i=0; i < nya.markers.length; i++)
    {
      if (nya.markers[i].detected)
      {  
         nya.markers[i].beginTransform(pgl);
  
         translate(0,0,20);
  
         // if it's the hiro marker, draw a cube
         if (i == 0)
         {
           rotateX(radians(-90));
           //translate(0,-60,0);
           noStroke();
           scale( 0.015, -0.015, 0.015 );
           scene.draw();
           //model.draw();
           //stroke(255,200,0);
           //box(40);
         }
       // else draw a sphere
       else
         {
         //stroke(0,200,255);
         if (nya.markers[0].detected)
         {
           angulo2 = nya.markers[0].angle.z;
           stroke(0, 102, 0);
           if ((angulo1 >= 0 && angulo2 < 0) || (angulo1 < 0 && angulo2 >= 0))
           {
             angulo1 *= -1;
           }
           variacao = (int)(10*(angulo2 - angulo1));
           angulo1 = angulo2;
         }
         rotateX(radians(-90));
         noStroke();
         if(variacao > 0)
           model2.scale(1.05);
         else if (variacao < 0)
           model2.scale(0.95);
         model2.draw();
         variacao = 0;
       }
       nya.markers[i].endTransform();
      }
    }
    
    
  }
}

