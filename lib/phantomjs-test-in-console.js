var page, system;

page = require('webpage').create();

system = require('system');

// TODO replace test-in-console with actual driver package
console.log("phantomjs: Running tests at " + system.env.ROOT_URL + " using test-in-console");

page.onConsoleMessage = function (message) {
  console.log(message);
};

page.open(system.env.ROOT_URL);

page.onError = function (msg, trace) {
  var mochaIsRunning;
  mochaIsRunning = page.evaluate(function () {
    return window.mochaIsRunning;
  });
  if (mochaIsRunning) {
    return;
  }
  console.log("phantomjs: " + msg);
  trace.forEach(function (item) {
    console.log("    " + item.file + ": " + item.line);
  });
  phantom.exit(6);
};

setInterval(function () {
  var done, failures;
  done = page.evaluate(function () {
    if (typeof TEST_STATUS !== "undefined" && TEST_STATUS !== null) {
      return TEST_STATUS.DONE;
    }
    if (typeof DONE !== "undefined" && DONE !== null) {
      return DONE;
    }
    return false;
  });
  if (done) {
    failures = page.evaluate(function () {
      if (typeof TEST_STATUS !== "undefined" && TEST_STATUS !== null) {
        return TEST_STATUS.FAILURES;
      }
      if (typeof FAILURES !== "undefined" && FAILURES !== null) {
        return FAILURES;
      }
      return false;
    });
    return phantom.exit(failures ? 2 : 0);
  }
}, 500);

// ---
// generated by coffee-script 1.9.2