#include <LiquidCrystal.h>
#include <Vector.h>
#include "pitches.h"

/************************Reusable Code*****************************************/
#define NUMBER_OF_PADS 4
#define NUMBER_OF_LEVELS 9
#define READ_BUTTON_PIN 0
#define DEBOUNCE_BUTTON_THRESHOLD 150
#define BUZZER_PIN 15
#define PAUSE_TONE 500
#define PAUSE_NO_TONE 250

//void(* resetFunc) (void) = 0;

enum ButtonPressedType {RIGHT, UP, DOWN, LEFT, SELECT, PASS};

class ButtonHandler {
  private:
    void (*functions[6])();

    int readValue() {
      int value = analogRead(READ_BUTTON_PIN);

      if (value < 650) {
        delay(DEBOUNCE_BUTTON_THRESHOLD);
        value = analogRead(READ_BUTTON_PIN);
      }

      return value;
    }

    ButtonPressedType getPressedButton() {
      int value = readValue();

      if (value < 10) {
        return RIGHT;
      } else if (value < 110) {
        return UP;
      } else if (value < 260) {
        return DOWN;
      } else if (value < 420) {
        return LEFT;
      } else if (value < 650) {
        return SELECT;
      } else return PASS;
    }


  public:
    ButtonHandler() {
      for (int i = 0; i < 6; i++) {
        functions[i] = NULL;
      }
    }

    void addAction(void (*f)(), ButtonPressedType type) {
      functions[type] = f;
    }

    void handleAction() {
      ButtonPressedType type = getPressedButton();
      if (functions[type] != NULL)
        functions[type]();
    }
};

#define PIN_PAD_1 A8
#define PIN_PAD_2 A9
#define PIN_PAD_3 A10
#define PIN_PAD_4 A11
#define PAD_THRESHOLD 20

class PadHandler {
  private:
    void (*functions[4])();
    int readValue(int pinPad) {
      int value = analogRead(pinPad);
      if (value > 30) {
        delay(PAD_THRESHOLD);
      } else return 0;

      return value;
    }

  public:
    PadHandler() {
      for (int i = 0; i < 4; i++)
        functions[i] = NULL;
    }

    void addAction(void (*f)(), int padNumber) {
      functions[padNumber] = f;
    }

    void handleAction() {
      int valuePad1 = readValue(PIN_PAD_1);
      int valuePad2 = readValue(PIN_PAD_2);
      int valuePad3 = readValue(PIN_PAD_3);
      int valuePad4 = readValue(PIN_PAD_4);
      if (valuePad1 != 0) functions[0]();
      if (valuePad2 != 0) functions[1]();
      if (valuePad3 != 0) functions[2]();
      if (valuePad4 != 0) functions[3]();
    }
};

/********************Reusable Code********************************************/
const int freq[] = {NOTE_C2, NOTE_D3, NOTE_E4, NOTE_F5};

class Level {
  private:
    int n, currentSize;
    int correctResponse[13];
    int currentResponse[13];
    int match, order;

  public:
    Level() {
    }

    Level(int ordine, int n) {
      this->n = n;
      this->currentSize = 0;
      //      const int freq[] = {NOTE_C2, NOTE_D3, NOTE_E4, NOTE_F5};
      match = 0;
      this->order = ordine;
      for (int i = 0; i < n; i++) {
        this->correctResponse[i] = freq[random(NUMBER_OF_PADS)];
      }
    }

    int getOrder() {
      return this->order;
    }

    void add(int freq) {
      this->currentResponse[currentSize++] = freq;
    }

    void startLevel() {
      currentSize = 0;
    }

    void stopLevel() {
      int newMatch = 0;
      for (int i = 0; i < n; i++) {
        if (correctResponse[i] == currentResponse[i]) {
          newMatch++;
        }
      }

      if (newMatch > match) match = newMatch;
    }

    int getCurrentLevelSize() {
      return currentSize;
    }

    int getFreq(int i) {
      return correctResponse[i];
    }

    bool isFinished() {
      return getCurrentLevelSize() == getLevelSize();
    }

    String sendFreq(int i) {
      return String(getIndexOfNote(correctResponse[i])) + ":" + String(correctResponse[i]);
    }

    int getIndexOfNote(int note) {

      for (int i = 0; i < NUMBER_OF_PADS; i++) {
        if (freq[i] == note) return i;
      }

      return -1;
    }

    int getLevelSize() {
      return n;
    }

    String getLevelInfo() {
      return String(order) + ":" + String(match) + "/" + String(getLevelSize()) + ";";
    }

    String getOnlyLevelStatus() {
      return String(match) + "/" + String(getLevelSize());
    }
};


ButtonHandler buttonHandler;
PadHandler padHandler;
LiquidCrystal lcd(8, 9, 4, 5, 6, 7);

Level levels[NUMBER_OF_LEVELS] = {
  Level(0, 4),
  Level(1, 5),
  Level(2, 6),
  Level(3, 7),
  Level(4, 8),
  Level(5, 9),
  Level(6, 10),
  Level(7, 11),
  Level(8, 12)
};

/***************************Game State****************************************/
enum GameState {START, LEVELS, GAME_LISTEN, GAME_ME, RESTART};

Level currentLevel;
int currentLevelIndex;

GameState currentState = START;
/***************************Game State****************************************/

void setup() {
  lcd.begin(2, 16);

  Serial.begin(9600);

  initButtonsAction();
  initPadAction();
}

void loop() {
  if (currentState == START || currentState == LEVELS || currentState == RESTART) {
    buttonHandler.handleAction();
  } else if (currentState == GAME_LISTEN) {
    sendMusic();
    currentState = GAME_ME;
  } else if (currentState == GAME_ME) {
    padHandler.handleAction();
    if (levels[currentLevelIndex].isFinished()) {
      levels[currentLevelIndex].stopLevel();

      lcd.setCursor(0, 0);
      lcd.print(levels[currentLevelIndex].getOnlyLevelStatus());
      //send info to pc
      Serial.write("s:s");

      currentState = RESTART;
      delay(200);
      Serial.write(levels[currentLevelIndex].getLevelInfo().c_str());
      Serial.write('\n');
    }
  }
}

void sendMusic() {
  lcd.setCursor(0, 0);
  lcd.print(levels[currentLevelIndex].getLevelSize());
  for (int i = 0; i < levels[currentLevelIndex].getLevelSize(); i++) {
    Serial.write(levels[currentLevelIndex].sendFreq(i).c_str());
    sound(levels[currentLevelIndex].getFreq(i));
  }
}

void serialEvent() {
  if (Serial.available()) {
    if (currentState == START) {
      String str = Serial.readString();
      lcd.print(str);
      if (str.equals("exit")) {
        Serial.write("exit");
//        resetFunc();
      } else {
        sendLevles();
        currentState = LEVELS;
      }
    } else if (currentState == LEVELS) {
      String level = Serial.readString();
      lcd.clear();
      lcd.print(level);
      currentLevelIndex = getLevel(level);
      levels[currentLevelIndex].startLevel();
//      lcd.print(currentLevel.getOnlyLevelStatus());
      currentState = GAME_LISTEN;
    } else if (currentState == RESTART) {
      String startOrLevel = Serial.readString();
      lcd.print(startOrLevel);
      if (startOrLevel.equals("start")) {
        currentState = START;
      } else {
        currentState = LEVELS;
        sendLevles();
      }
    }
  }
}

int getLevel(String level) {
  level.trim();
  for (int i = 0; i < NUMBER_OF_LEVELS; i++) {
    if (String(i).equals(level))
      return i;
  }
  lcd.print("II nou oricum");
  return -1;
}

void sendLevles() {
  String str = "";
  for (int i = 0; i < NUMBER_OF_LEVELS; i++) {
    str = str + levels[i].getLevelInfo();
  }
  str = str + "\n";
  Serial.write(str.c_str());
}

//send actions to PC
void initButtonsAction() {
  buttonHandler.addAction(left, LEFT);
  buttonHandler.addAction(right, RIGHT);
  buttonHandler.addAction(down, DOWN);
  buttonHandler.addAction(up, UP);
  buttonHandler.addAction(select, SELECT);
}

void initPadAction() {
  padHandler.addAction(pad1, 0);
  padHandler.addAction(pad2, 1);
  padHandler.addAction(pad3, 2);
  padHandler.addAction(pad4, 3);
}

//button handlers
void left() {
  Serial.write(LEFT);
}

void right() {
  Serial.write(RIGHT);
}

void up() {
  Serial.write(UP);
}

void down() {
  Serial.write(DOWN);
}

void select() {
  Serial.write(SELECT);
}

//pad hanlders
void sound(int freq) {
  tone(BUZZER_PIN, freq);
  delay(PAUSE_TONE);
  noTone(BUZZER_PIN);
  delay(PAUSE_NO_TONE);
}

void pad1() {
  Serial.print("0:" + String(freq[0]));
  sound(freq[0]);
  levels[currentLevelIndex].add(freq[0]);
}

void pad2() {
  Serial.print("1:" + String(freq[1]));
  sound(freq[1]);
  levels[currentLevelIndex].add(freq[1]);
}

void pad3() {
  Serial.print("2:" + String(freq[2]));
  sound(freq[2]);
  levels[currentLevelIndex].add(freq[2]);
}

void pad4() {
   Serial.print("3:" + String(freq[3]));
   sound(freq[3]);
   levels[currentLevelIndex].add(freq[3]);
}
