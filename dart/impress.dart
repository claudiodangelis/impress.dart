#import('dart:html');

class Vector {
  num x = 0, y = 0, z = 0;
}

class State {
  Vector rot;
  Vector pos;
  num scale = 1;

  State() : rot = new Vector(), pos = new Vector();
}

class Config {
  num height;
  num width;
  num maxScale;
  num minScale;
  num perspective;
  num transitionDuration;

  num getAttribute(Element root, String a, num def) =>
      (root.attributes[a] == null) ?
        def : Math.parseDouble(root.dataset[a]);

  Config(Element root)
  {
    height = getAttribute(root,"height",768);
    width = getAttribute(root,"width",1024);
    maxScale = getAttribute(root,"maxScale",1);
    minScale = getAttribute(root,"minScale",0);
    perspective = getAttribute(root,"perspective",1000);
    transitionDuration = getAttribute(root,"transitionDuration",1000);
  }
}

class Impress {

  // The top level elements
  Element mImpress;
  Element mCanvas;
  // List of all available steps
  ElementList mSteps;
  // Index of the currently active step
  int mCurrentStep;

  Config mCfg;

  Impress()
  {
    mImpress = document.query('#impress');
    mImpress.innerHTML = '<div id="canvas">'+ mImpress.innerHTML +'</div>';
    mCanvas = document.query('#canvas');
    mSteps = mCanvas.queryAll('.step');
    mCurrentStep = 0;
    mCfg = new Config(mImpress);
  }

  num winScale()
  {
    num hScale = document.window.innerHeight / mCfg.height;
    num wScale = document.window.innerWidth / mCfg.width;
    num scale = Math.min(hScale,wScale);
    scale = Math.min(mCfg.maxScale,scale);
    scale = Math.max(mCfg.minScale,scale);
    return scale;
  }

  String bodyCSS() =>
    "height: 100%; overflow-x: hidden; overflow-y: hidden;";

  String stepCSS(String s) =>
    "position: absolute; -webkit-transform: translate(-50%, -50%) ${s}; -webkit-transform-style: preserve-3d;";

  String stateToCSS(State state) =>
      "translate3d(${state.pos.x}px, ${state.pos.y}px, ${state.pos.z}px) rotateX(${state.rot.x}deg) rotateY(${state.rot.y}deg) rotateZ(${state.rot.z}deg) scale(${state.scale})";

  String canvasCSS(State state) =>
      "position: absolute; -webkit-transform-origin: 0% 0%; -webkit-transition: all 500ms ease-in-out 0ms; -webkit-transform-style: preserve-3d; -webkit-transform: rotateZ(${-state.rot.z}deg) rotateY(${-state.rot.y}deg) rotateX(${-state.rot.x}deg) translate3d(${-state.pos.x}px, ${-state.pos.y}px, ${-state.pos.z}px);";

  String scaleCSS(State state) {
      num windowScale = winScale();
      num targetScale = windowScale / state.scale;
      num perspective = mCfg.perspective / targetScale;
      return "position: absolute; -webkit-transform-origin: 0% 0%; -webkit-transition: all 500ms ease-in-out 250ms; -webkit-transform-style: preserve-3d; top: 50%; left: 50%; -webkit-transform: perspective(${perspective}) scale(${targetScale});";
  }

  void setupPresentation() {
    // Body and html
    document.body.style.cssText = bodyCSS();

    document.head.innerHTML = document.head.innerHTML + '<meta content="width=device-width, minimum-scale=1, maximum-scale=1, user-scalable=no" name="viewport">';

    // Create steps
    mSteps.forEach((Element step) =>
      step.style.cssText = stepCSS(stateToCSS(getState(step)))
    );

    // Create Canvas
    mCanvas.style.cssText = canvasCSS(getState(mSteps[0]));
    mCanvas.elements.first.remove();

    // Scale and perspective
    mImpress.style.cssText = scaleCSS(getState(mSteps[0]));
  }

  num getAttribute(Element step, String a, num def) =>
    (step.attributes[a] == null) ?
      def : Math.parseDouble(step.attributes[a]);

  State getState(Element step) {
    // We know we want a number, so we can "statically cast"
    num attr(String a, [num def = 0]) => getAttribute(step, a, def);
    State s = new State();
    s.scale = attr('data-scale', 1);
    s.pos.x = attr('data-x');
    s.pos.y = attr('data-y');
    s.pos.z = attr('data-z');
    s.rot.x = attr('data-rotate-x');
    s.rot.y = attr('data-rotate-y');
    // Treat data-rotate as data-rotate-z:
    // Allows using only data-rotate for pure 2D rotation
    s.rot.z = attr('data-rotate-z', attr('data-rotate'));
    return s;
  }

  void goto(int step) {
    // Iterate over attributes of the step jumped to and apply CSS
    mCurrentStep = step;
    print(canvasCSS(getState(mSteps[mCurrentStep])));
    mCanvas.style.cssText = canvasCSS(getState(mSteps[mCurrentStep]));
    // Scale and perspective
    mImpress.style.cssText = scaleCSS(getState(mSteps[mCurrentStep]));
  }

  void prev() {
    int prev_ = mCurrentStep - 1;
    goto(prev_ >= 0 ? prev_ : mSteps.length-1);
  }

  void next() {
    int next_ = mCurrentStep + 1;
    goto(next_ < mSteps.length ? next_ : 0);
  }
}

void main() {

  Impress pres = new Impress();
  pres.setupPresentation();

  // trigger impress action (next or prev) on keyup
  document.on.keyUp.add((event) {
    switch (event.keyCode) {
      case 33: // pg up
        pres.prev();
        break;
      case 37: // left
        pres.prev();
        break;
      case 38: // up
        pres.prev();
        break;
      case 9:  // tab
        pres.next();
        break;
      case 32: // space
        pres.next();
        break;
      case 34: // pg down
        pres.next();
        break;
      case 39: // right
        pres.next();
        break;
      case 40: // down
        pres.next();
        break;
    }
    event.preventDefault();
  });

  window.on.hashChange.add((e) {
    int slideNr = Math.parseInt(window.location.hash.replaceFirst(new RegExp('^#\/?'), ''));
    print(slideNr);
    pres.goto(slideNr);
  });


  /* not used atm

  // delegated handler for clicking on the links to presentation steps
  document.on.click.add((event) {
    // event delegation with "bubbling"
    // check if event taget (or any of its parents is a link)
    var target = event.target;
    while ((target.tagName !== "A") &&
           (target !== document.documentElement)) {
      target = target.parentNode;
    }

    if (target.tagName === "A") {
      var href = target.getAttribute("href");

      // if it's a link to presentation step, target this step
      if (href && href[0] === "#") {
        target = document.query(href.slice(1));
      }
    }

    if (pres.goto(target) != null) {
      event.stopImmediatePropagation();
      event.preventDefault();
    }
  });

  // delegated handler for clicking on step elements
  document.on.click.add((event) {
    var target = event.target;
    // find closest step element that is not active
    while (!(target.classes.contains("step") && !target.classes.contains("active") &&
            (target !== document.documentElement))) {
      target = target.parentNode;
    }
    if (pres.goto(target) != null) {
      event.preventDefault();
    }
  });

  // touch handler to detect taps on the left and right side of the screen
  document.on.touchStart.add((event) {
    if (event.touches.length === 1) {
      var x = event.touches[0].clientX;
      var width = window.innerWidth * 0.3;
      var result = null;

      if (x < width) {
        result = pres.prev();
      } else if (x > window.innerWidth - width) {
        result = pres.next();
      }

      if (result) {
        event.preventDefault();
      }
    }
  });
*/
  // rescale presentation when window is resized
  window.on.resize.add(throttle((event) {
    // force going to active step again, to trigger rescaling
    pres.goto(pres.mCurrentStep);
  }, 250));

}

/**
 * Throttling function calls
 */
throttle(fn, int delay) {
  int handle = 0;
  return (args) {
    window.clearTimeout(handle);
    handle = window.setTimeout(() => fn(args), delay);
  };
}

