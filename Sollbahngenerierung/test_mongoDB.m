%%
% Pfad zur MongoDB Java-Treiber JAR-Datei hinzufügen

javaaddpath('/Users/felix/MATLAB/Projects/Zeitreihenanalyse_Matlab/Sollbahngenerierung/mongodb-driver-sync-4.2.3.jar');
javaaddpath('/Users/felix/MATLAB/Projects/Zeitreihenanalyse_Matlab/Sollbahngenerierung/bson-4.2.3.jar');
javaaddpath('/Users/felix/MATLAB/Projects/Zeitreihenanalyse_Matlab/Sollbahngenerierung/mongodb-driver-core-4.2.3.jar');


% Importieren der benötigten Java-Klassen
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoDatabase;
import org.bson.Document;

% Verbindungszeichenfolge für MongoDB Atlas
uri = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
%'mongodb+srv://felixthomas:felixthomas@cluster0-shard-00-00.su3gj7l.mongodb.net:27017,cluster0-shard-00-01.su3gj7l.mongodb.net:27017,cluster0-shard-00-02.su3gj7l.mongodb.net:27017/your_database_name?ssl=true&replicaSet=atlas-sv0qu7-shard-0&authSource=admin&retryWrites=true&w=majority';

% Verbindung zu MongoDB herstellen
client = MongoClients.create(uri);
database = client.getDatabase('robotervermessung');  % Ersetzen Sie durch den tatsächlichen Namen der Datenbank

% Beispielabfrage: Abrufen der ersten 10 Dokumente aus der Sammlung "your_collection"
collection = database.getCollection('robotervermessung');  % Ersetzen Sie durch den Namen der Sammlung
cursor = collection.find().limit(10).iterator();

% Anzeigen der Dokumente
while cursor.hasNext()
    document = cursor.next();
    disp(char(document.toJson()));
end

% Verbindung schließen
client.close();


%%

% 
%     % DBConfig laden
%     db_config = loadDBConfig();
%     config = db_config;
% 
%     % Benutzername und Passwort
%     user = matlab.net.URLEncoder.encode(config.username);
%     password = matlab.net.URLEncoder.encode(config.password);
%     uri = config.connection_string;
%     db_name = config.db_name;
%     collection_name_header = config.collection_name_header;
%     collection_name_trajectories = config.collection_name_trajectories;
% 
%     % Verbindung herstellen
%     uri_with_credentials = sprintf('%s:%s@%s', user, password, uri);
%     client = com.mongodb.client.MongoClients.create(uri_with_credentials);
%     try
%         % Ping senden, um eine erfolgreiche Verbindung zu bestätigen
%         client.getDatabase('admin').runCommand(org.bson.Document('ping', 1));
%         disp('Pinged your deployment. You successfully connected to MongoDB!');
% 
%         % Datenbank und Sammlungen abrufen
%         db = client.getDatabase(db_name);
%         collection_header = db.getCollection(collection_name_header);
%         collection_trajectories = db.getCollection(collection_name_trajectories);
% 
%         % Hier können weitere Datenbankoperationen durchgeführt werden
% 
%         % Verbindung schließen
%         client.close();
%     catch ex
%         disp(ex.getMessage());
%     end
% 
% 
% function db_config = loadDBConfig()
%     % DBConfig laden
%     cd = fileparts(mfilename('fullpath'));
%     config_full_path = fullfile(cd, 'dbconfig.json');
%     file = fopen(config_full_path, 'r');
%     config_content = fread(file, '*char')';
%     fclose(file);
% 
%     % JSON in Struktur konvertieren
%     db_config = jsondecode(config_content);
% end
% 
% 
% 
% % uri = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
% % server = "felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net";
% % port = 27017;
% % dbname = "robotervermessung";
% % conn = mongoc(server,port,dbname)