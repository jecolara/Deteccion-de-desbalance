% --- Configuracion inicial ---
% Guardar datos en un archivo .mat
file_name = 'mb.mat';
fs = 10000; % Frecuencia de muestreo (Hz)
duration = 10; % Duracion de la adquisicion (segundos)

% Sensibilidad del acelerometro en mV/g
sensibilidad = 0.1; % Sensibilidad de 100 mV/g

% Estimacion de la frecuencia fundamental
f_variador = 15; %frecuencia de alimentacion del motor

np = 4; %número de polos del motor

rpm = (f_variador * 120)/np; %rpm del motor

omega = rpm*(2*pi/60); %velocidad angular del motor

% Estimación de la frecuencia fundamental
f_fundamental = omega/(2*pi);

% Definir el ancho de banda del filtro (ajustar segun tus necesidades)
ancho_banda = 2;  % Ancho de banda en Hz

% Definir el rango de frecuencias del filtro
frecuencia_min = f_fundamental - ancho_banda/2;
frecuencia_max = f_fundamental + ancho_banda/2;

filtro = designfilt('bandpassiir', 'FilterOrder', 4, ...
                    'HalfPowerFrequency1', frecuencia_min, ...
                    'HalfPowerFrequency2', frecuencia_max, ...
                    'SampleRate', fs);

% Crear sesión de adquisición
s = daq.createSession('ni');
% Se configuran los modulos de la DAQ
addAnalogInputChannel(s, 'cDAQ1Mod1', 3, 'IEPE'); % Chumacera 1 - Vertical
addCounterInputChannel(s, 'cDAQ1Mod5', 0, 'EdgeCount'); %Sensor optico                
                
s.DurationInSeconds = duration; %Duración de la captura de datos
s.Rate = fs; %frecuencia de muestreo

% Adquirir datos de los modulos configurados
[data, time] = s.startForeground();

fprintf('Iniciando adquisicion...\n');


% Datos del canal correspondiente
data_channel = data(:, 1);
    
% Convertir de V a g (por la sensibilidad de 100 mV/g)
acceleration_g = data_channel / sensibilidad; % Aceleración en g
    
% Convertir de g a mm/s^2
acceleration_m_per_s2 = acceleration_g * 9810; % Aceleración en mm/s^2

%En caso de solo querer los datos de un único acelerómetro, elimine el for
%y trabaje solo con la columna que le corresponda al acelerómetro
%También asegure de colocar un nombre especifico al archivo guardado en la
%linea 104

figure;

% --- Procesamiento, graficacion y guardado ---
    
acc = acceleration_m_per_s2(:,1);

% Aplicar filtro pasa banda
filtered_acceleration = filter(filtro, acc);

% --- Gráfico de la señal en el tiempo ---
subplot(1, 2, 1);
plot(time, filtered_acceleration, 'b');
xlabel('Tiempo (s)');
ylabel('Aceleracion (mm/s^2)');
title('Se�al filtrada en el tiempo - Sensor ');
grid on;

% --- Transformada Rápida de Fourier (FFT) ---
L = length(filtered_acceleration); % Número de muestras
fft_data = fft(filtered_acceleration); % Aplicar FFT a los datos filtrados
P2 = abs(fft_data / L); % Magnitud de la FFT
P1 = P2(1:L/2+1); % Mitad positiva
P1(2:end-1) = 2 * P1(2:end-1); % Escalar magnitudes

f = fs * (0:(L/2)) / L; % Eje de frecuencias (Hz)

% Gráfico del espectro de frecuencias
subplot(1, 2, 2);
plot(f, P1, 'r');
xlabel('Frecuencia (Hz)');
ylabel('Amplitud');
title('Espectro de frecuencias - Sensor ');
xlim([0 50]);
grid on;

% --- Detectar frecuencia dominante ---
[max_amp, idx] = max(P1); % Amplitud máxima y su índice
freq_dominant = f(idx);   % Frecuencia dominante en Hz

% Almacenar la frecuencia dominante en el archivo .mat
save(file_name, 'data', 'time', 'filtered_acceleration', 'P1', 'freq_dominant', '-v7.3');


% Calcular los pulsos por segundo a partir de los datos del contador
% Supongamos que la segunda columna es el contador
contador = data(:, 2);  % Datos del contador
time_stamps = time;  % Tiempos de adquisición

% Calcular la diferencia entre las lecturas consecutivas del contador (delta)
deltas = diff(contador);  % Diferencia entre los pulsos consecutivos
delta_times = diff(time_stamps);  % Diferencia de tiempos correspondientes

% Calcular los pulsos por segundo (frecuencia de los pulsos)
pulsos_por_segundo = deltas ./ delta_times;  % Pulsos por segundo
pulsos_por_segundo(end+1) = 0;


load(file_name, 'filtered_acceleration', 'P1', 'freq_dominant'); % Datos del sensor 1 como ejemplo

% Graficar los pulsos por segundo
figure;
plot(time, filtered_acceleration, '-r', 'LineWidth', 2);
xlabel('Tiempo (s)');
ylabel('Aceleracion por revolucion');
title('Frecuencia de pulsos (pulsos por segundo)');
hold on;
plot(time, (pulsos_por_segundo>1)*1000, 'b');
grid on;

[peaks1, locs1] = findpeaks(pulsos_por_segundo, fs);
[peaks2, locs2] = findpeaks(filtered_acceleration, fs);

delta_t = locs2(1) - locs1(1);

if delta_t <0
    delta_t = locs2(2) - locs1(1);
end

fase = mod((delta_t * 360)/(1/f_fundamental),360);

% Almacenar la frecuencia dominante en el archivo .mat
save(file_name, 'data', 'time', 'filtered_acceleration', 'P1', 'freq_dominant', 'fase', '-v7.3');

fprintf('Adquisicion y procesamiento completados. Resultados guardados.\n');

% % --- Resumen general al final del procesamiento ---
disp('--- Resumen de analisis ---');
    
% Mostrar información resumida
disp(['Sensor: Frecuencia dominante = ', num2str(freq_dominant), ' Hz, Amplitud maxima = ', num2str(max(P1)),'mm/s2']);
disp(['Sensor: Fase = ', num2str(fase)]);

