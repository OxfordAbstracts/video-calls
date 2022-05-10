exports.initCallFrameImpl = function (opts) {
  return function (error, success) {
    const DailyIframe = require("@daily-co/daily-js");
    const panzoom = require("@panzoom/panzoom");
    const callFrame = DailyIframe.createFrame(opts.el, opts.createFrameOpts);

    const dragElement = document.querySelector("#" + opts.dragElementId);
    const controls = document.querySelector("#" + opts.controlsElementId);

    if (dragElement && controls) {
      const callboxHeight = 16 * 34.5;
      const { height } = dragElement.parentElement.getBoundingClientRect();

      const startY = height - callboxHeight - 16; // one rem from the bottom
      dragElement.style.transform = "translateY(" + startY + "px)";

      if (startY > 0) {
        panzoom(dragElement, {
          exclude: [opts.el, controls],
          disableZoom: true,
          contain: "inside",
          startY: startY,
        });
        
        setTimeout(function () {
          dragElement.style.opacity = 1;
        })
      }

      callFrame.on("left-meeting", () => {
        const event = new Event('leave-call-event');
        dragElement.dispatchEvent(event)
      });
    }

    return callFrame
      .join()
      .then(function () {
        callFrame.setUserName(opts.createFrameOpts.userName, {
          thisMeetingOnly: true,
        });
        success(callFrame);
      })
      .catch(function (err) {
        console.log("daily init err", err);
        error(err);
      });
  };
};

exports.leaveCallImpl = function (callFrame) {
  return function (error, success) {
    var left = false;
    callFrame.on("left-meeting", () => {
      if (!left) {
        success({});
      }
    });
    callFrame.leave();

    setTimeout(function () { // Leave after a couple seconds even if the event doesn't fire
      if (!left) {
        success({});
      }
    }, 2000);
  };
};

exports.destroyCall = function (callFrame) {
  return function () {
    callFrame.destroy();
  };
};
