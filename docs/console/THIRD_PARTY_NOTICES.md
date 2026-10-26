# Third-party source and binary notices

The KonSol RetroStation web console uses independent original HTML, CSS and JavaScript source kept in this repository. The following **separately licensed** runtime components are downloaded only during the GitHub Pages build. Never strip the original notices from their files:

1. **YoWASP openFPGALoader WebAssembly package** — `@yowasp/openfpgaloader@1.1.1-182.269`, package license **ISC**. https://github.com/YoWASP/openFPGALoader-web. The exact generated `bundle.js` and `openFPGALoader.wasm` are SHA-256 checked against the existing PiKoSoL release assets before being placed on GitHub Pages. Package metadata is retained by the build.
2. **coi-serviceworker v0.1.7**, copyright Guido Zuidhof and contributors; license **MIT**; original project https://github.com/gzuidhof/coi-serviceworker. The MIT header is retained. An exact pinned file from the Sipeed-FPGA project is copied into the Pages build and verified by Git blob SHA.
3. **openFPGALoader** and device programming functionality are contained in the above third-party package; consult original project terms at https://github.com/trabucayre/openFPGALoader and do not infer ownership from this web UI.
4. **FPGA game source** remains in KonSol RetroStation (K-BLOCKS) and Sipeed-FPGA (PONG / BREAKOUT) under their respective licenses. The generated Gowin bitstreams may additionally be subject to separate device/vendor IP and tool license terms.

There is no historical commercial ROM, game audio sample, proprietary game art, Flash-writer UI or general-purpose FPGA programming endpoint in this site.
