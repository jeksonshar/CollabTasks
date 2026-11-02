"use strict";

const path = require("path");
const {spawnSync} = require("child_process");

const functionsDir = path.resolve(__dirname, "..");
const checks = [
    {
        name: "lint",
        script: path.join(functionsDir, "node_modules", "eslint", "bin", "eslint.js"),
        args: ["--ext", ".js,.ts", "--ignore-pattern", "scripts/predeploy.js", "."],
    },
    {
        name: "build",
        script: path.join(functionsDir, "node_modules", "typescript", "bin", "tsc"),
        args: [],
    },
];

/** Runs Functions lint and compilation without spawning the Windows npm shim. */
function runPredeployChecks() {
    for (const check of checks) {
        console.log(`[predeploy] Running ${check.name}`);
        const result = spawnSync(process.execPath, [check.script, ...check.args], {
            cwd: functionsDir,
            stdio: "inherit",
        });

        if (result.error) {
            console.error(`[predeploy] Failed to run ${check.name}:`, result.error);
            process.exitCode = 1;
            return;
        }
        if (result.status !== 0) {
            process.exitCode = result.status || 1;
            return;
        }
    }
}

runPredeployChecks();
