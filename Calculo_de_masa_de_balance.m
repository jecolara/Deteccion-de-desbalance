% Calculo de la masa de desbalance mediante el metodo de tres vectores

% --- Configuracion inicial ---
clc;
clear;

% Cargar datos de los acelerometros y vueltas
load('mo.mat', 'P1', 'fase'); % Datos del sensor 1 como ejemplo

% --- Paso 1: Amplitud inicial de desbalance (OA) ---
OA = max(P1); % Amplitud inicial del espectro de frecuencias
faseInicial = fase;
x0 = OA*cos(deg2rad(faseInicial));
y0 = OA*sin(deg2rad(faseInicial));

% --- Paso 2: Agregar masa de prueba ---
m_ensayo = 64; % Masa de ensayo en gramos
posicionEnsayo = 0; %Posicion de la masa de prueba con respecto a la marca

% --- Paso 3: Medicion con masa de prueba (OB) ---
load('me.mat', 'P1', 'fase'); % Espectro con masa de prueba
OB = max(P1); % Amplitud con masa de ensayo
faseEnsayo = fase;
x1 = OB*cos(deg2rad(faseEnsayo));
y1 = OB*sin(deg2rad(faseEnsayo));

suma_x = x1 - x0;
suma_y = y1 - y0;

% Calcular la magnitud y el ángulo del vector resultante
AB = sqrt(suma_x^2 + suma_y^2);
angulo_resultante = mod(rad2deg(atan2(suma_y, suma_x)),360); % Convertir ángulo a grados
V = [AB, OA, OB]; %Para escalar las masas en el gráfico polar
A = max(V)+ (max(V)/2);

beta = ((faseInicial+180)-angulo_resultante);
% --- Paso 5: Calculo de la masa de balanceo (mb) ---
m_desbalance = m_ensayo * (OA / AB); % Masa de balanceo en gramos

% --- Paso 6: Posicion de la masa de balanceo ---
posicionbalance = mod(posicionEnsayo - abs(beta),360);

% --- Mostrar resultados ---
fprintf('Resultados del Calculo de Desbalance:\n');
fprintf('Amplitud inicial (OA): %.4f mm/s^2\n', OA);
fprintf('Amplitud con masa de ensayo (OB): %.4f mm/s^2\n', OB);
fprintf('Vector AB: %.4f mm/s^2\n', AB);
fprintf('Masa de balanceo (mb): %.4f gramos\n', m_desbalance);
fprintf('Posicion de la masa de balanceo: %.2f grados\n', posicionbalance);

% --- Guardar resultados ---
resultados_balanceo = struct('OA', OA, 'OB', OB, 'AB', AB, 'm_desbalance', m_desbalance, 'posicionbalance', posicionbalance);
save('resultados_balanceo.mat', 'resultados_balanceo');

figure;
polarplot([0 deg2rad(faseInicial)], [0 OA], 'LineWidth', 2);
title('Gráfico Polar de la Amplitud vs Fase');
hold on;
polarplot([0 deg2rad(faseEnsayo)], [0 OB], 'LineWidth', 2);
title('Gráfico Polar de la Amplitud vs Fase');
hold on;
polarplot([0 deg2rad(angulo_resultante)], [0 AB], 'LineWidth', 2);
hold on;
polarplot(deg2rad(posicionbalance), A, 'x-', 'LineWidth', 2);
hold on;
polarplot(deg2rad(posicionEnsayo), A, 'x-', 'LineWidth', 2);
legend('Vector desbalance OA','Vector masa de prueba OB', 'Vector resultante', 'masa de balanceo', 'masa de prueba');
title('Gráfico Polar de la Amplitud vs Fase');
