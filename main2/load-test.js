import http from "k6/http";
import { sleep } from "k6";

export let options = {
  vus: 20, // број на виртуелни корисници
  duration: "1m", // траење
};

export default function () {
  http.get("http://4.175.237.48:8100/load");
  sleep(1);
}
