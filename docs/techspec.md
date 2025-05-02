# Technical Implementation Details  
## Prototype Game: "Shapes & Train" (Godot Engine)

---

### **1. Goal**
Implement a basic gameplay prototype:
- Drag-and-drop shapes through a forest maze with doors for different forms.
- Verify interactions between shapes, doors, and train cars.
- Provide visual and audio feedback for actions.

---

### **2. Scene Structure**

- **Main Scene:**  
  Contains the entire gameplay area (maze, start, train).
- **Shapes:**  
  Three types (circle, square, triangle), each as a Node2D with drag & drop logic.
- **Maze:**  
  Built with TileMap or manually arranged tile sprites for paths and "walls."
- **Maze Walls with Forest Theme:**  
   - **Bushes** — Green, fluffy, possibly with faces or berries.  
   - **Rocks** — Rounded, grey, may have flowers or bugs.  
   - **Trees** — Tree trunks or crown segments, bright and chunky.
- **Doors:**  
  Several doors, each with a cut-out for a specific shape. Checks if the shape fits.
- **Train:**  
  Decorative locomotive plus 3 train cars with holes for each specific shape.
- **UI:**  
  Basic buttons ("Retry", "Home"), simple pop-up messages ("Well done!").

---

### **3. Game Logic**

- **Drag & Drop:**  
  Implemented in GDScript (Mouse and/or Touch events).
- **Collisions:**  
  Basic CollisionShape2D for shapes, walls, doors, and train cars.
- **Door Validation:**  
  - If shape matches the door — animate/open door, play success sound.
  - If not — shake shape, play error sound.
- **Maze Navigation:**  
  Shape cannot pass through walls/decor.
- **Putting Shape in Train Car:**  
  If correct car — success with positive feedback; if not — display "Oops, not here."
- **Level Flow:**  
  Shapes appear one after another; each should reach the train.

---

### **4. Visuals**

- **Shapes & Doors:**  
  Temporary primitive drawing (Godot Circle/Rectangle) or basic PNG assets.
- **Maze:**  
  Paths and background as color fills; walls as bushes, rocks, trees (as tiles or sprites).
- **Train:**  
  Simplified look, but recognizable locomotive and cars.
- **Animations:**  
  At minimum: shape shaking, door opening, bounce effect on success.

---

### **5. Audio**

- Effects: door opening, mistake, placing shape in car.
- Short voice lines (as SFX or UI text): "Well done!", "Oops, not here!"
- Optional simple background music (easily toggled in script).

---

### **6. Project Folder Structure**

- `/scenes` — main scene, maze, train, cars, doors, shapes
- `/sprites` — tile images, walls, shapes, cars, train (png/svg or Godot shapes)
- `/audio` — sound effects and music
- `/scripts` — GDScript files for logic
- `/ui` — buttons, notification pop-ups

---

### **7. Technical Notes**

- **Recommended screen size:** 1280×720, or adaptable (mobile scaling optional).
- **Controls:** Mouse (desktop) and touch (mobile).
- **Assets:** Temporary or hand-drawn assets are fine, swap for final art later as desired.
- **Code:** Keep code readable and commented for easy future updates and extensions.

---

### **8. Coding Conventions**

- **Class Names:** PascalCase (e.g., `TrainCar`, `ShapeDoor`)
- **Variables & Functions:**
  - Private variables: snake_case with underscore prefix (`_variable_name`)
  - Public variables: snake_case without prefix (`variable_name`)
  - Constants: UPPERCASE_WITH_UNDERSCORES
  - Functions: snake_case (`func do_something()`)
  
- **Typing:**
  - Use strong typing for function parameters and return values (`func add(a: int, b: int) -> int:`)
  - Use type inference (`:=`) for local variables when type is clear (`var result := 10`)
  - Explicitly type class variables and exported properties

- **Node References:**
  - Use `@onready` variables to cache node references
  - Example: `@onready var _audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D`

- **Signals:**
  - Use async/await for signal handling when possible instead of connecting callbacks
  - Signal names should be past tense for events that happened (`shape_placed_correctly`)

- **Comments:**
  - Use comments to explain "why" rather than "what" 
  - Add a brief class description at the top of each script
  - Document complex algorithms and non-obvious behavior

- **Formatting:**
  - Use tabs for indentation
  - Use spaces around operators (`x = y + z`, not `x=y+z`)
  - Keep lines under 100 characters when possible

- **Organization:**
  - Group related variables and functions together
  - Order: constants, exported variables, regular variables, onready variables, signals, built-in functions (_ready, _process, etc.), custom functions
