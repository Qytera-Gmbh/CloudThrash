package de.besessener;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

public class App extends Application {

    @Override
    public void start(Stage primaryStage) throws Exception {
        // Load the FXML file
        Parent root = FXMLLoader.load(getClass().getResource("/de/besessener/ui.fxml"));

        // Create the scene
        Scene scene = new Scene(root);

        // Set the scene and title
        primaryStage.setScene(scene);
        primaryStage.setTitle("CloudThrash");

        // Load the application icon
        Image icon = new Image(getClass().getResourceAsStream("/de/besessener/app-icon.png"));
        primaryStage.getIcons().add(icon);

        // Show the stage
        primaryStage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
