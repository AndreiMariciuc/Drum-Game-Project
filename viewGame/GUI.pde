class Button {
  color col;
  String txt;
  boolean selected;

  Button(color col, String txt, boolean selected) {
    this.col = col;
    this.txt = txt;
    this.selected = selected;
  }

  void display(float x, float y, float widthX, float heightY) {
    if (this.selected == false) fill(col); 
    else fill(col + 40);
    rect(x, y, widthX, heightY, 20);
    textSize(20);
    fill(0);
    text(txt, x + widthX / 2 - txt.length() * 10, y + heightY / 2);
  }

  void select() {
    this.selected = true;
  }

  void setText(String txt) {
    this.txt = txt;
  }

  void diselect() {
    this.selected = false;
  }
}

public class Menu {
  private String txt;
  private float textX, textY;
  private int stateI, stateJ;
  private int n, m;
  private Button[][] buttons;

  Menu(int n, int m) {
    this.n = n;
    this.m = m;
    buttons = new Button[n][m];

    stateI = 0;
    stateJ = 0;
  }
  
  Button getSelected() {
    for(int i=0; i<n; i++) {
      for(int j=0; j<m; j++)
        if(buttons[i][j].selected)
          return buttons[i][j];
    }
    return null;
  }
  
  void setTextForButton(int i, int j, String txt) {
    buttons[i][j].setText(txt);
  }

  void addButton(Button button, int i, int j) {
    buttons[i][j] = button;
  }

  void addTitle(String txt, float textX, float textY) {
    this.txt = txt;
    this.textX = textX;
    this.textY = textY;
  }

  boolean handleAction(KeyBoardActions[] actions) {
    if (myPort.available() > 0) {
      int val = myPort.read();
      if (val > 4) {
        println("aici" + val);
        return false;
      }
      buttons[stateI][stateJ].diselect();
      switch(actions[val]) {
      case RIGHT:
        println("right");
        stateJ = (stateJ + 1) % m;
        break;
      case UP:
        println("up");
        stateI = stateI == 0 ? n - 1 : stateI - 1;
        break;
      case DOWN:
        println("down");
        stateI = (stateI + 1) % n;
        break;
      case LEFT:
        println("left");
        stateJ = stateJ == 0 ? m - 1 : stateJ - 1;
        break;
      case SELECT:
        println("select");
        buttons[stateI][stateJ].select();
        if(currentState == GameState.LEVELS) {
          myPort.write(String.valueOf(stateI * 3 + stateJ));
        } else 
          myPort.write(buttons[stateI][stateJ].txt);
        return true;
      }
      buttons[stateI][stateJ].select();
    }
    return false;
  }

  void display() {
    textSize(30);
    text(txt, textX, textY);

    float rataXButton = width / m;
    float rataYButton = (2 * height/3) / n;

    for (int i=0; i<n; i++) {
      for (int j=0; j<m; j++) {
        buttons[i][j].display(j * rataXButton, i * rataYButton + height/3, rataXButton, rataYButton);
      }
    }
  }
}

class MenuBuilder {
  private Menu menu;

  MenuBuilder(int n, int m) {
    menu = new Menu(n, m);
  }

  MenuBuilder withTitle(String txt, float textX, float textY) {
    this.menu.addTitle(txt, textX, textY);
    return this;
  }

  MenuBuilder withButton(Button button, int posi, int posj) {
    this.menu.addButton(button, posi, posj);
    return this;
  }

  Menu construct() {
    return this.menu;
  }
}

class PadDrawer {
  private float[] freq;
  private float startPos;
  private float graphSize;
  private color selectedColor;

  PadDrawer(float startPos, int freqSize, float graphSize, color col) {
    freq = new float[freqSize]; 
    freq[0] = 0;
    this.startPos = startPos;
    this.graphSize = graphSize;
    this.selectedColor = col;
  }

  void display() {
    if (freq[10] != 0) {
      fill(selectedColor);
      stroke(selectedColor);
    } else {
      fill(160);
      stroke(160);
    }
    //strokeWeight(0);
    //noStroke();
    rect(startPos, 0, graphSize, height);
    stroke(0);

    noFill();
    beginShape();
    for (int y=0; y < height; y++) {
      vertex(map(sin(freq[y] * y), -1, 1, startPos, graphSize), y);
    }
    endShape();

    rotateArrayRight();
  }

  void addFreq(int val) {
    for (int i=1; i<100; i++) {
      freq[i] = val;
    }
  }

  private void rotateArrayRight() {
    for (int i= freq.length - 1; i>=1; i--) freq[i] = freq[i-1];
  }
}

class PadHandler {
  private PadDrawer pad1, pad2, pad3, pad4;

  PadHandler() {
    pad1 = new PadDrawer(0, height, width/4, color(255, 0, 0));
    pad2 = new PadDrawer(width/4, height, 2*width/4, color(255, 100, 0));
    pad3 = new PadDrawer(width/2, height, 3*width/4, color(0, 255, 0));
    pad4 = new PadDrawer(3*width/4, height, width, color(0, 0, 255));
  }

  void handleArduinoAction() {
    if ( myPort.available() > 0) { 
      String val = myPort.readString();
      println(val);
      String[] parse = val.split(":");

      if (parse[0].equals("0")) {
        //println(parse[1]);
        pad1.addFreq(Integer.parseInt(parse[1]));
      }

      if (parse[0].equals("1")) {
        //println(parse[1]);
        pad2.addFreq(Integer.parseInt(parse[1]));
      }

      if (parse[0].equals("2")) {
        //println(parse[1]);
        pad3.addFreq(Integer.parseInt(parse[1]));
      }

      if (parse[0].equals("3")) {
        //println(parse[1]);
        pad4.addFreq(Integer.parseInt(parse[1]));
      }
      
      if(parse[0].equals("s")) {
        //println(parse[0]);
        background(155);
        currentState = GameState.RESTART;
      }
    }
    pad1.display();
    pad2.display();
    pad3.display();
    pad4.display();
  }
}
