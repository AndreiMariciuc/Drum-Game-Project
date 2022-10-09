import processing.serial.*;
import java.util.*;

/************Arduino Side****************/
final static int BAUD_RATE = 9600;
Serial myPort;
/************|Arduino Side****************/

/************Game Side*****************/
enum GameState {
  START, LEVELS, GAME, RESTART
}

enum KeyBoardActions {
  RIGHT, UP, DOWN, LEFT, SELECT
}
/************|Game Side*****************/

/************State Variables************/
GameState currentState = GameState.START;
Menu startMenu, levelsMenu, restartMenu;
PadHandler padHandler;
Map<GameState, Menu> gameToMenuMap = new HashMap();
/************|State Variables************/

void setup() 
{ 
  initArduinoPort();
  initGui();


  gameToMenuMap.put(GameState.START, startMenu);
  gameToMenuMap.put(GameState.LEVELS, levelsMenu);
  gameToMenuMap.put(GameState.RESTART, restartMenu);
  size(800, 700, P2D);

  padHandler = new PadHandler();
}

boolean readCommand = false;

Menu currentMenu;
void draw() {
  //background(155);
  currentMenu = gameToMenuMap.get(currentState);

  if (currentState != GameState.GAME)
    currentMenu.display();

  if (readCommand == false) {
    readCommand = (currentMenu.handleAction(KeyBoardActions.values()) == true);
    if (currentState == GameState.RESTART && readCommand == true) {
      if (currentMenu.getSelected().txt.equals("start")) {
        currentState = GameState.START;
        readCommand = false;  
      } else {
        readCommand = true;
        currentState = GameState.START;
      }
      background(155);
    } else if(currentState == GameState.START && readCommand == true) {
      if(currentMenu.getSelected().txt.equals("exit")){
        System.exit(0);
      }
    }
  } else {
    if (currentState == GameState.START && prepareLevel()) {
      currentState = GameState.LEVELS;
      readCommand = false;
      background(155);
      msg = "";
    } else if (currentState == GameState.LEVELS) {
      currentState = GameState.GAME;
    } else if (currentState == GameState.RESTART && prepareRestartMenu()) {
      println("sunt in restart");
      background(155);
      readCommand = false;
    } else if (currentState == GameState.GAME) 
      padHandler.handleArduinoAction();
  }
}

String msg = "";

boolean prepareRestartMenu() {
  if (myPort.available() > 0) {
    msg = myPort.readStringUntil('\n');
    if (msg == null) return false;
    String[] msgs = msg.split(":");
    restartMenu.txt = "OMG! Your score is " + msgs[1] + ", level" + msgs[0];
    msg = "";
    return true;
  }
  return false;
}

boolean prepareLevel() {
  if (myPort.available() > 1) {
    char c;
    do {
      c = (char) myPort.read();
      if (c == '/' || c == ':' || c == ';' || (c>= '0' && c <= '9'))
        msg = msg + c;
      print("m-am blocat");
    } while (c != '\n');

    createLevel(msg);
    return true;
  }

  return false;
}

void createLevel(String levels) {
  println(levels);
  int lineSize = 3;
  String[] realLevels = levels.split(";");
  for (String level : realLevels) {
    String[] date = level.split(":");
    println(date[0] + date[1]);
    int levelNumber = Integer.parseInt(date[0]);
    int i = levelNumber / lineSize;
    int j = levelNumber % lineSize;
    println(date[1]);
    println(i, j);
    levelsMenu.setTextForButton(i, j, date[1]);
  }

  msg = "";
}

void initGui() {
  color c = color(82, 26, 102);
  startMenu = new MenuBuilder(2, 1)
    .withTitle("Select", width / 2.4, 40.0f)
    .withButton(new Button(c, "start", true), 0, 0)
    .withButton(new Button(c, "exit", false), 1, 0)
    .construct();

  levelsMenu = new MenuBuilder(3, 3)
    .withTitle("Levels", width / 2.4, 40.f)
    .withButton(new Button(c, "", true), 0, 0)
    .withButton(new Button(c, "", false), 0, 1)
    .withButton(new Button(c, "", false), 0, 2)
    .withButton(new Button(c, "", false), 1, 0)
    .withButton(new Button(c, "", false), 1, 1)
    .withButton(new Button(c, "", false), 1, 2)
    .withButton(new Button(c, "", false), 2, 0)
    .withButton(new Button(c, "", false), 2, 1)
    .withButton(new Button(c, "", false), 2, 2)
    .construct();

  restartMenu = new MenuBuilder(2, 1)
    .withTitle("Place Holder", width / 2.4, 40.0f)
    .withButton(new Button(c, "start", true), 0, 0)
    .withButton(new Button(c, "levels", false), 1, 0)
    .construct();
}

void initArduinoPort() {
  printArray(Serial.list());

  try {
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, BAUD_RATE);
    println("You are now connected " + portName);
  } 
  catch(Exception e) {
    println("Wrong port input...");
    System.exit(-1);
  }
}
