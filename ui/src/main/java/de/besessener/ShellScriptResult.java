package de.besessener;

public class ShellScriptResult {
    private final int exitCode;
    private final String log;

    public ShellScriptResult(int exitCode, String log) {
        this.exitCode = exitCode;
        this.log = log;
    }

    public int getExitCode() {
        return exitCode;
    }

    public String getLog() {
        return log;
    }
}
