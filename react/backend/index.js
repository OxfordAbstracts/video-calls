const express = require("express");
const { createRoom, deleteRoom } = require("./daily-service");

const app = express();
const port = 4000;

app.use(express.json());

app.get("/hello", (req, res) =>
  res.send(`Hello ${req.query.name || "world"}!`)
);

app.post("/daily-room", async (req, res) => {
  const {
    one_to_one = false,
    enable_recording = false,
    owner_only_broadcast = false,
    user_id = 1,
  } = req.body;

  const response = await createRoom({
    max_participants: one_to_one ? 2 : 16,
    enable_recording: enable_recording,
    owner_only_broadcast: owner_only_broadcast,
    user_id: user_id,
    exp: new Date().getTime() + 600 * 1000,
  });

  res.send({ id: response.id, name: response.name });
});

app.delete("/daily-room/:room", async (req, res) => {
  const { room } = req.params;
  const response = await deleteRoom(room);
  res.send({ deleted: response.deleted });
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));
