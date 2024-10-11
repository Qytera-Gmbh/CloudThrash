package de.besessener;

import de.besessener.ShellScriptResult;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;

import javafx.application.Platform;
import javafx.concurrent.Task;
import javafx.scene.control.TextArea;

public class ShellScript {

    private static StringBuilder logBuilder = new StringBuilder();

    public static Task<ShellScriptResult> runShellScript(String scriptPath, TextArea logOutput) {
        return runShellScript(scriptPath, logOutput, null);
    }

    public static Task<ShellScriptResult> runShellScript(String scriptPath, TextArea logOutput,
            Map<String, String> env) {
        Task<ShellScriptResult> task = new Task<>() {
            @Override
            protected ShellScriptResult call() throws Exception {
                String gitBashPath = "C:/Program Files/Git/bin/bash.exe";

                logBuilder = new StringBuilder();
                logBuilder.append(logOutput.getText());
                logBuilder.append(getTimestamp()).append("Running ").append(scriptPath).append("\n");

                // Create ProcessBuilder and redirect error stream to output stream
                ProcessBuilder processBuilder = new ProcessBuilder(gitBashPath, "-c", scriptPath);
                processBuilder.redirectErrorStream(true); // Redirects stderr to stdout

                if (env != null && !env.isEmpty()) {
                    Map<String, String> processEnv = processBuilder.environment();
                    processEnv.putAll(env);
                }

                int exitCode = -1;

                try {
                    Process process = processBuilder.start();

                    BufferedReader stdoutReader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                    String line;

                    // Read and log all output from the process
                    while ((line = stdoutReader.readLine()) != null) {
                        logBuilder.append(getTimestamp()).append(line).append("\n");
                        updateLog(logOutput, logBuilder.toString());
                    }

                    // Wait for the process to finish
                    exitCode = process.waitFor();
                } catch (IOException | InterruptedException e) {
                    e.printStackTrace();
                    logBuilder.append(getTimestamp()).append(">> ").append(e.getMessage()).append("\n");
                    updateLog(logOutput, logBuilder.toString());
                }

                logBuilder.append(getTimestamp()).append("Exit code: ").append(exitCode).append("\n");
                logBuilder.append(getTimestamp()).append("-------------------\n");

                updateLog(logOutput, logBuilder.toString());

                return new ShellScriptResult(exitCode, logBuilder.toString());
            }
        };

        // Handle what happens when the task succeeds
        task.setOnSucceeded(event -> {
            ShellScriptResult result = task.getValue();
        });

        // Start the task on a background thread
        new Thread(task).start();

        // Return the task so that it can be used to check for completion or get results
        return task;
    }

    public static void updateLog(TextArea logOutput, String logText) {
        Platform.runLater(() -> {
            logOutput.setText(logText);
            logOutput.setScrollTop(Double.MAX_VALUE);
        });
    }

    private static String getTimestamp() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return "[" + sdf.format(new Date()) + "] ";
    }
}
