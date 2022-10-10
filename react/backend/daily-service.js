const fetch = require("node-fetch");

const daily_api_key =
  "1844647e30eb55387206a90b4302af9c64408016cd76b434f422ba2749b3e3b0";

const createRoom = async (config) => {
  const {
    max_participants = 2,
    enable_recording = false,
    owner_only_broadcast = false,
    private_call = false,
    user_id = 1,
    exp,
  } = config;
  return dailyApiPost("/rooms", {
    properties: {
      max_participants: max_participants,
      enable_recording: enable_recording,
      owner_only_broadcast: owner_only_broadcast,
      exp,
    },
    privacy: private_call ? "private" : "public",
  });
};

const getActiveParticipants = () => dailyApiGet("/presence");

const deleteRoom = (name) => dailyApiDelete(`/rooms/${name}`);

const dailyApiMethod = (method) => async (path, body) => {
  const config = {
    method: method,
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer " + daily_api_key,
    },
  };

  if (body) {
    config.body = JSON.stringify(body);
  }

  const response = await fetch("https://api.daily.co/v1" + path, {
    method: method,
    headers: {
      "Content-Type": "application/json",
      Authorization: "Bearer " + daily_api_key,
    },
  });
  return response.json();
};

const dailyApiPost = dailyApiMethod("POST");
const dailyApiGet = dailyApiMethod("GET");
const dailyApiDelete = dailyApiMethod("DELETE");

module.exports = { createRoom, getActiveParticipants, deleteRoom };
