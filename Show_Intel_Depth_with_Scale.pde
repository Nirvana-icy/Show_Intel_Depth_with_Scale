import intel.pcsdk.*; //import the Intel Perceptual Computing SDK

int rectScale = 10;

int[] depth_size = new int[2];
short[] depthMap;
PImage depthImage;
boolean getPointDepth = false;
PXCUPipeline session;

//Render engine for each depth value
color renderDepthWithColor(int depth)
{
  int colorIndex = 0;                  
  int depthToSeeMin = 100;            //Make the pixel which > depthToSeeMin and < depthToAnalysisMin with white color
  int depthToAnalysisMin = 100;      //depthToAnalysisMin and depthToAnalysisMax is the depth change area you want to analysis the depth value.
  int depthToAnalysisMax = 1400;      //When the depth value more close to depthToAnalysisMax,the color is more red. 
  int colorIndexChangeValue = int(256/(depthToAnalysisMax - depthToAnalysisMin));    //0 < depthToSeeMin < depthToAnalysisMin < depthToAnalysisMax
  
  color rectColor = color(100,100,100);  //defaut color is gray
  
  if(32001 == depth)
  {
    rectColor = color(0,0,255);
  }
  else
  {
    rectColor = color(map(depth, depthToAnalysisMin, depthToAnalysisMax, 0, 255),255 - map(depth, depthToAnalysisMin, depthToAnalysisMax, 0, 255),0);
  }
  return rectColor;
}

//Draw one rect with x y and depth value
void drawRect(int x, int y, int depth)
{
   fill(renderDepthWithColor(depth));
   rect(x*rectScale + 320, y*rectScale, rectScale, rectScale);
}

void setup()
{
  session = new PXCUPipeline(this);
  session.Init(PXCUPipeline.DEPTH_QVGA);

  //SETUP DEPTH MAP
  if(session.QueryDepthMapSize(depth_size))
  {
//    size(depth_size[0], depth_size[1]);
    size(1200,700);
    depthMap = new short[depth_size[0] * depth_size[1]];
    depthImage=createImage(depth_size[0], depth_size[1], ALPHA);
  }
}

void draw()
{ 
  if (session.AcquireFrame(false))
  {
    session.QueryDepthMap(depthMap);   
    
    //REMAPPING THE DEPTH IMAGE TO A PIMAGE
    for (int i = 0; i < depth_size[0]*depth_size[1]; i++)
    {
      depthImage.pixels[i] = color(map(depthMap[i], 0, 1400, 0, 255));
    }
    depthImage.updatePixels();
    if(getPointDepth)
    {
      println("x:" + mouseX);
      println("y:" + mouseY);
      println("Depth:" + depthMap[(mouseY - 1)*depth_size[0] + mouseX]);
      getPointDepth = false;
    }
      //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    for(int y = 120; y < 191; y++)
    {
      for(int x = 112; x < 201; x++)
      {
        drawRect(x - 112, y - 120, depthMap[y*depth_size[0] + x]);
      } 
    }
    session.ReleaseFrame();//VERY IMPORTANT TO RELEASE THE FRAME    
  }
  image(depthImage, 0, 0, depth_size[0], depth_size[1]);
}

void keyPressed() {
  println("pressed " + int(key) + " " + keyCode);
  if(keyCode == 83)
  {
    saveFrameToDisk();
  }
}


void saveFrameToDisk()
{
  //Get the current time 
  int yy = year();
  int mm = month();
  int dd = day();
  int hh = hour();
  int mi = minute();
  int ss = second();
  String Time = "Depth_" + yy + mm + dd + hh + mi + ss;
  //Write the depthMap[] to CSV Table
  Table table = new Table();
  //Write the first row  
  for(int i = 0; i < depth_size[0]; i++)
  {
      table.addColumn(i +"");
  }
  //Write the other row
  for(int RowNum = 0; RowNum < depth_size[1]; RowNum ++)
  {
    TableRow newRow = table.addRow();
    for(int i = 0; i < depth_size[0]; i++)
    {
      newRow.setInt(i +"", depthMap[RowNum*depth_size[0] + i]);
    }
  } 
  //Save the Table to the disk
  saveTable(table, Time + ".csv" );
}

void mousePressed()
{
  if(mouseX < 320 && mouseY < 240)
  {
    getPointDepth = true;
  }
}
