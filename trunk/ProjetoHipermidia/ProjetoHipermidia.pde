/*************************************************/
/* PCS2057 - Multimídia e Hipermídia             */
/* Projeto: Arquitetura com realidade aumentada  */
/* Autores: Bruno Nigro                          */
/*          Fernando Nobre                       */
/*          Marco Massaki Horoiwa                */
/*************************************************/
 
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.opengl.*;
import javax.media.opengl.*;
import mri.*;

Capture cam;
NyARMultiBoard nya;
V3dsScene casa, telhado;
PFont font;
boolean inicio = false;
int comandoAnterior, comandoAtual;
float angulo1, angulo2, variacao;
float anguloCasa;
float posicaoTelhado;
float xLuz, yLuz;
float escala = 0.1;


// Formata um ângulo
String angle2text(float a)
{
  int i=(int)degrees(a);
  i=(i>0?i:i+360);
  return (i<100?"  ":i<10?" ":"")+Integer.toString(i);
}

// Formata um número
String trans2text(float i)
{
  return (i<100?"  ":i<10?" ":"")+Integer.toString((int)i);
}

// Desenha as coordenadas dos marcadores
void drawMarkerPos(int[][] pos2d)
{
  textFont(font,10.0);
  stroke(100,0,0);
  fill(100,0,0);
  
  for(int i=0;i<4;i++){
    ellipse(pos2d[i][0], pos2d[i][1],5,5);
  }
  
  fill(0,0,0);
  for(int i=0;i<4;i++){
    text("("+pos2d[i][0]+","+pos2d[i][1]+")",pos2d[i][0],pos2d[i][1]);
  }
}

// Configura a luz do ambiente
void setupLight( GL g, float[] pos, float val )
{
  float[] light_emissive = { 1.0f, 1.0f, 1.0f, 1 };
  float[] light_ambient = { 1f, 1f, 1f, 1 };
  float[] light_diffuse = { 1.0f, 1.0f, 1.0f, 1.0f };
  float[] light_specular = { 0.0f, 0.0f, 0.0f, 0.0f };  
  float[] light_position = { pos[0], pos[1], pos[2], val };  

  g.glLightfv ( GL.GL_LIGHT1, GL.GL_AMBIENT, light_ambient, 0 );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_DIFFUSE, light_diffuse, 0 );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_SPECULAR, light_specular, 0 );
  g.glLightfv ( GL.GL_LIGHT1, GL.GL_POSITION, light_position, 0 );  
  g.glEnable( GL.GL_LIGHT1 );
  g.glEnable( GL.GL_LIGHTING );
    
  g.glEnable( GL.GL_COLOR_MATERIAL );
}  

void setup() {
  // trecho para funcionamento no OSX
  try 
  {
    quicktime.QTSession.open();
  } 
  catch (quicktime.QTException qte) 
  {
    qte.printStackTrace();
  }
  
  size(640,480,OPENGL);
  hint( ENABLE_OPENGL_4X_SMOOTH );
  smooth();
  frameRate(60);
  font=createFont("FFScala", 32);
  cam=new Capture(this,width,height);
  
  // Modelos 
  casa = new V3dsScene(this, "house_open.3ds" );
  telhado = new V3dsScene(this, "house_roof.3ds");
  
  //Marcadores
  String[] patts = {"casa.pat", "controle.pat", "rotacao.pat", "telhado.pat", "sol.pat", "zoom.pat"};
  double[] widths = {80,80,80,80,80,80};
  
  // inicializa o NyARMultiBoard
  nya=new NyARMultiBoard(this,width,height,"camera_para.dat",patts,widths);
  print(nya.VERSION);
  nya.gsThreshold=120;//(0<n<255) default=110
  nya.cfThreshold=0.4;//(0.0<n<1.0) default=0.4

  xLuz = 1000;
  yLuz = 0;
}

void draw() {
  
  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
  
  
  if (cam.available() !=true) {
    return;
  }

  cam.read();
  hint(DISABLE_DEPTH_TEST);
  image(cam,0,0);
  background(cam);

  if (nya.detect(cam))
  {
    
    text((int)(nya.markers[0].confidence*100)+"%",width-60,height-20);
    
    // Desenha a posição dos marcadores
    for (int i=0; i < nya.markers.length; i++)
    {
      if (nya.markers[i].detected)
      {
        textFont(font,25.0);
        fill((int)((1.0-nya.markers[i].confidence)*100),(int)(nya.markers[i].confidence*100),0);
        //text((int)(nya.markers[i].confidence*100)+"%",width-60,height-20);
        pushMatrix();
        textFont(font,10.0);
        fill(0,100,0,255);
        translate((nya.markers[i].pos2d[0][0]+nya.markers[i].pos2d[1][0]+nya.markers[i].pos2d[2][0]+nya.markers[i].pos2d[3][0])/4+50,(nya.markers[i].pos2d[0][1]+nya.markers[i].pos2d[1][1]+nya.markers[i].pos2d[2][1]+nya.markers[i].pos2d[3][1])/4+50);
        text("TRANS "+trans2text(nya.markers[i].trans.x)+","+trans2text(nya.markers[i].trans.y)+","+trans2text(nya.markers[i].trans.z),0,0);
        text("ANGLE "+angle2text(nya.markers[i].angle.x)+","+angle2text(nya.markers[i].angle.y)+","+angle2text(nya.markers[i].angle.z),100,15);
        popMatrix();  
        drawMarkerPos(nya.markers[i].pos2d);
      }
    }
    
    hint(ENABLE_DEPTH_TEST);
    
    comandoAnterior = comandoAtual;
    
    if(nya.markers[2].detected)
      comandoAtual = 2;
    else if(nya.markers[3].detected)
      comandoAtual = 3;
    else if(nya.markers[4].detected)
      comandoAtual = 4;
    else if(nya.markers[5].detected)
      comandoAtual = 5;
      
    if (comandoAnterior != comandoAtual)
      inicio = true;
    else inicio = false;
    // Se for o marcador de casa, desenha a casa
      if (nya.markers[0].detected)
      {
         nya.markers[0].beginTransform(pgl);
  
             rotateX(radians(-90));
             GL _gl = pgl.beginGL(); 
             // Configura a iluminção 
             setupLight( _gl, new float[]{xLuz, yLuz, 0}, 1 );
             pgl.endGL();
             translate(-30,0,20);
             //Rotaciona a casa
             rotateY(anguloCasa);
             noStroke();
             scale(escala, -escala, escala);
             
             casa.draw();
             translate(0, 1000*posicaoTelhado, 0);
             telhado.draw();
             
             nya.markers[0].endTransform();
      }
      
      if (nya.markers[1].detected)
      {
        nya.markers[1].beginTransform(pgl);
        
             if (inicio)
               angulo1 =  nya.markers[1].angle.z;
             else angulo1 = angulo2;
             angulo2 = nya.markers[1].angle.z;
             if ((angulo1 >= 0 && angulo2 < 0) || (angulo1 < 0 && angulo2 >= 0))
             {
               angulo1 *= -1;
             }
             variacao = angulo2 - angulo1;
             
        nya.markers[1].endTransform();   
      }
      
      nya.markers[comandoAtual].beginTransform(pgl);
      switch (comandoAtual)
      {
           case 2:
             anguloCasa = anguloCasa + variacao;
             break;
           case 3:
             posicaoTelhado = posicaoTelhado + variacao;
             if(posicaoTelhado < 0)
               posicaoTelhado = 0;
             break;
           case 4:
             xLuz = xLuz + 250 * variacao;
             if (xLuz > 1000)
               xLuz = 1000;
             else if (xLuz < -1000)
               xLuz = -1000;
             yLuz = sqrt(1000000 - xLuz*xLuz);
             break;
           case 5:
             escala = escala + 0.1 * variacao;
             if (escala < 0.1)
               escala = 0.1;
             break;
       }
       
       nya.markers[comandoAtual].endTransform();
  }
    
}

