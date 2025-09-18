import http from "k6/http";
import { sleep } from "k6";

export let options = {
  vus: 20, // број на виртуелни корисници
  duration: "1m", // траење
};

export default function () {
  http.get("http://48.222.221.49/load");
  sleep(1);
}
