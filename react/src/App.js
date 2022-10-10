import { useState } from "react";
import VideoFrame from "./VideoFrame";

function App() {
  const [count, setCount] = useState(0);
  const [hello, setHello] = useState("");
  const [dailyConfig, setDailyConfig] = useState(null);
  const [closing, setClosing] = useState(false);

  const sayHello = async () => {
    const response = await fetch("/hello");
    const text = await response.text();
    setHello(text);
  };

  const getDailyRoom = async () => {
    const response = await fetch("/daily-room", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        one_to_one: true,
        enable_recording: false,
        owner_only_broadcast: false,
        user_id: 1,
      }),
    });
    const { id, name } = await response.json();
    setClosing(false);
    setDailyConfig({ id, name });
  };

  return (
    <div className="w-80 mx-auto border p-4 border-gray-500 text-center">
      {count}
      <button
        onClick={() => setCount(count + 1)}
        className="w-full border border-gray-500 rounded"
      >
        +1!
      </button>
      <button
        onClick={() => sayHello().then()}
        className="w-full border border-gray-500 rounded mt-2"
      >
        Say hello
      </button>
      <div>{hello}</div>
      <button
        className="w-full border border-gray-500 rounded mt-4"
        onClick={getDailyRoom}
      >
        Connect to daily.io
      </button>
      {dailyConfig && (
        <div
          id="daily_video_drag_element"
          className="p-1 absolute w-[500px] h-[500px] border border-gray-200 rounded shadow-xl bg-gray-50 left-0 right-0 mx-auto"
        >
          <div
            className="flex justify-between items-center p-1"
            id="daily_video_box_controls_element"
          >
            Room name: {dailyConfig.name}
            <button
              className="border-gray-200 rounded p-2"
              onClick={() => {
                setClosing(true);
              }}
            >
              close
            </button>
          </div>
          <VideoFrame
            name="Finn"
            roomName={dailyConfig.name}
            closing={closing}
            hangUp={() => setDailyConfig(null)}
          />
        </div>
      )}
    </div>
  );
}

export default App;
