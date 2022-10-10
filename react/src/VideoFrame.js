import { useEffect, useRef, useState } from "react";
import DailyIframe from "@daily-co/daily-js";
import panzoom from "@panzoom/panzoom";

const VideoFrame = ({ name, roomName, closing, hangUp }) => {
  const ref = useRef(null);
  const [callFrame, setCallFrame] = useState(null);

  useEffect(() => {
    if (!callFrame) {
      initCallFrame(
        {
          el: ref.current,
          createFrameOpts: createFrameOpts({ userName: name, room: roomName }),
          dragElementId: "daily_video_drag_element",
        },
        hangUp
      ).then(setCallFrame);
    }
    return () => {
      callFrame?.destroy();
      fetch(`/daily-room/${roomName}`, { method: "DELETE" }).then();
    };
  }, []);

  useEffect(() => {
    if (closing) {
      callFrame?.destroy();
      fetch(`/daily-room/${roomName}`, { method: "DELETE" }).then();
      hangUp();
    }
  });
  return <section ref={ref} className="w-full h-full" />;
};

export default VideoFrame;

const createFrameOpts = ({ room, userName }) => ({
  url: `https://oa-test-video.daily.co/${room}`,
  userName: userName,
  showLeaveButton: false,
  showFullscreenButton: true,
  iframeStyle: { height: "100%", width: "100%" },
});

const initCallFrame = (opts) => {
  const callFrame = DailyIframe.createFrame(opts.el, opts.createFrameOpts);
  const dragElement = document.querySelector("#" + opts.dragElementId);

  panzoom(dragElement, {
    exclude: [opts.el],
    disableZoom: true,
  });

  return callFrame
    .join()
    .then(function () {
      callFrame.setUserName(opts.createFrameOpts.userName, {
        thisMeetingOnly: true,
      });
      return callFrame;
    })
    .catch(function (err) {
      console.log("Call frame error: ", err);
      return null;
    });
};
