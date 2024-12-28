function qam_constellation()
    % Fonction principale pour générer la constellation M-QAM avec bruit
    M = input('Entrez la taille de la M-QAM (4, 8, 16, 32, 64, 128, 512, 1024, 2048, 4096): ');
    valid_sizes = [4, 8, 16, 32, 64, 128, 512, 1024, 2048, 4096];
    
    if ismember(M, valid_sizes)
        disp('Génération de la constellation M-QAM et exportation des résultats...');
        plot_qam_constellation(M);
        disp('Fichiers PDF et CSV générés avec succès !');
    else
        fprintf('Taille invalide. Veuillez choisir parmi : %s.\n', mat2str(valid_sizes));
    end
end

function [points, excluded_points] = generate_qam_constellation(M, exclude_points)
    % Génère les points de constellation M-QAM
    side_len = sqrt(M);

    % Ajustement des côtés pour certains cas spécifiques
    switch M
        case 8
            side_len_x = 4; side_len_y = 2;
        case 32
            side_len_x = 6; side_len_y = 6;
        case 128
            side_len_x = 12; side_len_y = 12;
        case 512
            side_len_x = 24; side_len_y = 24;
        case 2048
            side_len_x = 46; side_len_y = 46;
        otherwise
            side_len_x = side_len; side_len_y = side_len;
    end

    % Génère tous les points possibles dans la grille
    [X, Y] = meshgrid(-side_len_x+1:2:side_len_x-1, -side_len_y+1:2:side_len_y-1);
    points = [X(:), Y(:)];

    % Exclut les points à l'origine
    points(all(points == 0, 2), :) = [];

    excluded_points = [];
    if exclude_points > 0
        % Exclusion des coins si nécessaire
        square_size = floor(sqrt(exclude_points / 4));
        excluded_points = [];
        for i = 0:square_size-1
            for j = 0:square_size-1
                excluded_points = [excluded_points; 
                    side_len_x-1-2*i, side_len_y-1-2*j;
                    -side_len_x+1+2*i, side_len_y-1-2*j;
                    side_len_x-1-2*i, -side_len_y+1+2*j;
                    -side_len_x+1+2*i, -side_len_y+1+2*j];
            end
        end
        % Supprime les points exclus
        mask = ~ismember(points, excluded_points, 'rows');
        points = points(mask, :);
    end
end

function plot_qam_constellation(M)
    % Paramètres spécifiques pour certaines tailles M-QAM
    exclusions = containers.Map({32, 128, 512, 2048}, {4, 16, 64, 196});
    if isKey(exclusions, M)
        exclude_points = exclusions(M);
    else
        exclude_points = 0;
    end

    % Génération des points de la constellation
    [points, excluded_points] = generate_qam_constellation(M, exclude_points);

    % Conversion des points en format complexe
    symbols = points(:, 1) + 1j * points(:, 2);

    % --- Ajout de bruit ---
    SNR_dB = input('Entrez la valeur du bruit (SNR) en dB: ');
    SNR_linear = 10^(SNR_dB / 10); % Conversion en valeur linéaire
    signal_power = mean(abs(symbols).^2); % Puissance moyenne du signal
    noise_power = signal_power / SNR_linear; % Puissance du bruit
    noise = sqrt(noise_power / 2) * (randn(size(symbols)) + 1j * randn(size(symbols))); % Bruit complexe
    noisy_symbols = symbols + noise; % Symboles bruités

    % --- Calcul de l'énergie et de la phase ---
    % Symboles originaux
    energy = abs(symbols).^2; % Énergie
    phase = angle(symbols); % Phase en radians
    phase(phase < 0) = phase(phase < 0) + 2 * pi; % Normalisation à [0, 2*pi]

    % Symboles bruités
    noisy_energy = abs(noisy_symbols).^2;
    noisy_phase = angle(noisy_symbols);
    noisy_phase(noisy_phase < 0) = noisy_phase(noisy_phase < 0) + 2 * pi;

    % --- Visualisation de la constellation ---
    figure;
    scatter(real(noisy_symbols), imag(noisy_symbols), 'b', 'DisplayName', 'Symboles bruités');
    hold on;
    scatter(real(symbols), imag(symbols), 'r*', 'DisplayName', 'Symboles originaux');
    grid on;
    title(sprintf('%d-QAM : Diagramme de constellation avec bruit (SNR = %d dB)', M, SNR_dB));
    xlabel('In-Phase (I)');
    ylabel('Quadrature (Q)');
    axis equal;
    legend;

    % Définition des axes
    max_val = max(abs(symbols)) + 5;
    xlim([-max_val, max_val]);
    ylim([-max_val, max_val]);

    % Sauvegarde du graphique
    desktop_path = fullfile(getenv('USERPROFILE'), 'Desktop', 'M-QAM');
    if ~isfolder(desktop_path)
        mkdir(desktop_path); % Crée le dossier si inexistant
    end
    pdf_filename = fullfile(desktop_path, sprintf('%d-QAM_constellation_bruit.pdf', M));
    saveas(gcf, pdf_filename);
    close;

    % --- Exportation des données ---
    data = [(1:length(symbols))', real(symbols), imag(symbols), energy, phase, ...
            real(noisy_symbols), imag(noisy_symbols), noisy_energy, noisy_phase];
    headers = {'Symbole', 'I (Orig.)', 'Q (Orig.)', 'Energie (Orig.)', 'Phase (Orig.)', ...
               'I (Bruit)', 'Q (Bruit)', 'Energie (Bruit)', 'Phase (Bruit)'};

    % Sauvegarde dans un fichier CSV
    csv_filename = fullfile(desktop_path, sprintf('%d-QAM_data.csv', M));
    writecell([headers; num2cell(data)], csv_filename);
    fprintf('Fichiers PDF et CSV générés avec succès dans %s\n', desktop_path);
end
