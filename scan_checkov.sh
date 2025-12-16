#!/bin/bash

# Affiche le répertoire courant
echo "Current directory: $(pwd)"

# Liste des dossiers à scanner (chemins relatifs pour TP-6)
directories=(
    "./terraform"
    "./k8s"
)

# Liste des frameworks à analyser
frameworks=(
    "terraform"
    "kubernetes"
    "secrets"
)

# Crée le dossier pour les rapports s'il n'existe pas déjà
mkdir -p reports_checkov

# Vérifie l'existence des dossiers
for directory in "${directories[@]}"; do
    if [ -d "$directory" ]; then
        echo "Directory $directory exists."
    else
        echo "Directory $directory does not exist. Skipping..."
        continue
    fi

    # Scan chaque dossier avec chaque framework et génère un rapport
    for framework in "${frameworks[@]}"; do
        echo "Scanning directory $directory with framework $framework..."
        # Sanitize the directory name to use in the report filename (remplace / et . par _)
        safe_dir_name=$(echo "$directory" | sed 's#[/\.]#_#g' | sed 's#^_##')
        outfile="reports_checkov/${framework}_${safe_dir_name}_report.json"
        # Lancer checkov et écrire le rapport dans un nom de fichier sûr
        checkov -d "$directory" --quiet --framework "$framework" -o json > "$outfile" 2>/dev/null
        echo "Checkov scan completed for $directory with framework $framework."
    done
done

echo "Génération des rapports consolidés..."

# Génère d'abord un rapport Markdown pour l'IA
md_file="reports_checkov/rapport_tp6_analyse.md"
cat > "$md_file" << 'EOF'
# Rapport de Sécurité et Conformité - TP-6

**Date de génération:** $(date '+%Y-%m-%d %H:%M:%S')

## Table des matières
1. [Résumé Exécutif](#résumé-exécutif)
2. [Statistiques Détaillées](#statistiques-détaillées)
3. [Échecs de Sécurité par Catégorie](#échecs-de-sécurité-par-catégorie)
4. [Recommandations Prioritaires](#recommandations-prioritaires)
5. [Détails Complets des Échecs](#détails-complets-des-échecs)

---

## Résumé Exécutif

### Vue d'ensemble
Ce rapport présente l'analyse de sécurité et de conformité du TP-6, incluant l'infrastructure Terraform et les manifestes Kubernetes.

EOF

# Variables pour le comptage global
total_passed=0
total_failed=0
total_skipped=0

# Analyse les fichiers JSON et extrait les statistiques
echo "### Statistiques par Framework" >> "$md_file"
echo "" >> "$md_file"

for json_file in reports_checkov/*.json; do
    if [ -f "$json_file" ]; then
        if command -v jq &> /dev/null; then
            passed=$(jq '.summary.passed // 0' "$json_file" 2>/dev/null || echo "0")
            failed=$(jq '.summary.failed // 0' "$json_file" 2>/dev/null || echo "0")
            skipped=$(jq '.summary.skipped // 0' "$json_file" 2>/dev/null || echo "0")
        else
            passed=$(grep -oP '"passed":\s*\K\d+' "$json_file" 2>/dev/null | head -1 || echo "0")
            failed=$(grep -oP '"failed":\s*\K\d+' "$json_file" 2>/dev/null | head -1 || echo "0")
            skipped=$(grep -oP '"skipped":\s*\K\d+' "$json_file" 2>/dev/null | head -1 || echo "0")
        fi
        
        passed=${passed:-0}
        failed=${failed:-0}
        skipped=${skipped:-0}
        
        total_passed=$((total_passed + passed))
        total_failed=$((total_failed + failed))
        total_skipped=$((total_skipped + skipped))
        
        framework=$(basename "$json_file" | cut -d'_' -f1)
        directory=$(basename "$json_file" | cut -d'_' -f2- | sed 's/_report.json//')
        
        echo "**$framework - $directory:**" >> "$md_file"
        echo "- ✅ Passés: $passed" >> "$md_file"
        echo "- ❌ Échoués: $failed" >> "$md_file"
        echo "- ⊘ Ignorés: $skipped" >> "$md_file"
        echo "" >> "$md_file"
    fi
done

# Calcule le total et le pourcentage
total_checks=$((total_passed + total_failed))
if [ $total_checks -gt 0 ]; then
    success_rate=$(awk "BEGIN {printf \"%.1f\", ($total_passed/$total_checks)*100}")
else
    success_rate="0.0"
fi

cat >> "$md_file" << EOF

### Résultat Global
- **Total de contrôles:** $total_checks
- **✅ Contrôles réussis:** $total_passed
- **❌ Contrôles échoués:** $total_failed
- **⊘ Contrôles ignorés:** $total_skipped
- **📊 Taux de conformité:** $success_rate%

---

## Détails Complets des Échecs

EOF

# Extraction détaillée des échecs avec jq
for json_file in reports_checkov/*.json; do
    if [ -f "$json_file" ] && command -v jq &> /dev/null; then
        framework=$(basename "$json_file" | cut -d'_' -f1)
        directory=$(basename "$json_file" | cut -d'_' -f2- | sed 's/_report.json//')
        
        echo "### $framework - $directory" >> "$md_file"
        echo "" >> "$md_file"
        
        # Extraction des échecs
        failed_count=$(jq '.summary.failed // 0' "$json_file")
        
        if [ "$failed_count" -gt 0 ]; then
            echo "**Nombre d'échecs:** $failed_count" >> "$md_file"
            echo "" >> "$md_file"
            
            # Détails de chaque échec
            jq -r '.results.failed_checks[]? | "#### " + .check_name + "\n" + 
                "- **ID:** " + .check_id + "\n" + 
                "- **Ressource:** " + .resource + "\n" + 
                "- **Fichier:** " + .file_path + "\n" + 
                "- **Lignes:** " + (.file_line_range | tostring) + "\n" + 
                "- **Guide:** " + .guideline + "\n"' "$json_file" >> "$md_file" 2>/dev/null
            
            echo "" >> "$md_file"
        else
            echo "✅ Aucun échec détecté" >> "$md_file"
            echo "" >> "$md_file"
        fi
    fi
done

cat >> "$md_file" << 'EOF'

---

## Recommandations Prioritaires

### Sécurité Kubernetes
1. **Configurer seccomp profiles:** Activer les profils seccomp (docker/default ou runtime/default)
2. **Limiter les Service Account Tokens:** Ne monter les tokens que là où nécessaire
3. **Utiliser read-only filesystem:** Configurer les conteneurs avec système de fichiers en lecture seule
4. **Restreindre les capabilities:** Ne donner que les capabilities nécessaires
5. **Éviter les conteneurs privilégiés:** Désactiver le mode privileged
6. **Définir des limites de ressources:** Configurer CPU et mémoire limits/requests
7. **Utiliser des images signées:** Vérifier la signature des images

### Sécurité Terraform
1. **Chiffrement:** S'assurer que toutes les ressources sensibles sont chiffrées
2. **Accès réseau:** Restreindre les accès réseau au strict nécessaire
3. **Authentification forte:** Utiliser l'authentification multi-facteur
4. **Logs et monitoring:** Activer les logs pour toutes les ressources critiques
5. **Gestion des secrets:** Ne jamais stocker de secrets en dur

### Secrets
1. **Scanner régulièrement:** Vérifier qu'aucun secret n'est exposé dans le code
2. **Utiliser des gestionnaires de secrets:** Azure Key Vault, Kubernetes Secrets
3. **Rotation des secrets:** Implémenter une rotation régulière

---

## Fichiers de Rapport

- **Rapport Markdown:** `rapport_tp6_analyse.md` (ce fichier)
- **Rapport HTML:** `rapport_tp6.html`
- **Rapport PDF:** `rapport_tp6.pdf`
- **Rapports JSON détaillés:** `*.json`

---

*Rapport généré par Checkov - Infrastructure as Code Security Scanner*
EOF

echo "✓ Rapport Markdown généré: $md_file"

# Génère un rapport HTML consolidé
html_file="reports_checkov/rapport_tp6.html"
cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de Sécurité TP-6</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px;
            line-height: 1.6;
        }
        h1 { 
            color: #2c3e50; 
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        h2 { 
            color: #34495e; 
            margin-top: 30px;
            border-left: 4px solid #3498db;
            padding-left: 10px;
        }
        h3 { 
            color: #7f8c8d; 
            margin-top: 20px;
        }
        .summary {
            background: #ecf0f1;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .passed { color: #27ae60; font-weight: bold; }
        .failed { color: #e74c3c; font-weight: bold; }
        .skipped { color: #f39c12; font-weight: bold; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border: 1px solid #bdc3c7;
        }
        th {
            background: #3498db;
            color: white;
        }
        tr:nth-child(even) {
            background: #f8f9fa;
        }
        .check-detail {
            background: #fff;
            border: 1px solid #ddd;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .timestamp {
            color: #95a5a6;
            font-style: italic;
        }
    </style>
</head>
<body>
    <h1>Rapport de Sécurité et Conformité - TP-6</h1>
    <p class="timestamp">Généré le: $(date '+%Y-%m-%d %H:%M:%S')</p>
    
    <div class="summary">
        <h2>Résumé Global</h2>
EOF

# Variables pour le comptage global
total_passed=0
total_failed=0
total_skipped=0

# Analyse les fichiers JSON et extrait les statistiques
for json_file in reports_checkov/*.json; do
    if [ -f "$json_file" ]; then
        # Extraction des statistiques avec jq si disponible, sinon grep basique
        if command -v jq &> /dev/null; then
            passed=$(jq '.summary.passed // 0' "$json_file" 2>/dev/null || echo "0")
            failed=$(jq '.summary.failed // 0' "$json_file" 2>/dev/null || echo "0")
            skipped=$(jq '.summary.skipped // 0' "$json_file" 2>/dev/null || echo "0")
        else
            passed=$(grep -oP '"passed":\s*\K\d+' "$json_file" 2>/dev/null | head -1 || echo "0")
            failed=$(grep -oP '"failed":\s*\K\d+' "$json_file" 2>/dev/null | head -1 || echo "0")
            skipped=$(grep -oP '"skipped":\s*\K\d+' "$json_file" 2>/dev/null | head -1 || echo "0")
        fi
        
        # Assure que les valeurs sont des nombres
        passed=${passed:-0}
        failed=${failed:-0}
        skipped=${skipped:-0}
        
        total_passed=$((total_passed + passed))
        total_failed=$((total_failed + failed))
        total_skipped=$((total_skipped + skipped))
        
        framework=$(basename "$json_file" | cut -d'_' -f1)
        directory=$(basename "$json_file" | cut -d'_' -f2- | sed 's/_report.json//')
        
        cat >> "$html_file" << INNER_EOF
        <h3>$framework - $directory</h3>
        <p><span class="passed">✓ Passés: $passed</span> | <span class="failed">✗ Échoués: $failed</span> | <span class="skipped">⊘ Ignorés: $skipped</span></p>
INNER_EOF
    fi
done

# Calcule le total et le pourcentage
total_checks=$((total_passed + total_failed))
if [ $total_checks -gt 0 ]; then
    success_rate=$(awk "BEGIN {printf \"%.1f\", ($total_passed/$total_checks)*100}")
else
    success_rate="0.0"
fi

cat >> "$html_file" << EOF
        <hr>
        <h3>Total</h3>
        <p>
            <span class="passed">✓ Total Passés: $total_passed</span> | 
            <span class="failed">✗ Total Échoués: $total_failed</span> | 
            <span class="skipped">⊘ Total Ignorés: $total_skipped</span>
        </p>
        <p><strong>Taux de conformité: $success_rate%</strong></p>
    </div>

    <h2>Détails Complets des Échecs</h2>
EOF

# Ajoute les détails complets pour chaque scan
for json_file in reports_checkov/*.json; do
    if [ -f "$json_file" ] && command -v jq &> /dev/null; then
        framework=$(basename "$json_file" | cut -d'_' -f1)
        directory=$(basename "$json_file" | cut -d'_' -f2- | sed 's/_report.json//')
        
        cat >> "$html_file" << INNER_EOF
        <div class="check-detail">
            <h2>$framework - $directory</h2>
INNER_EOF
        
        failed_count=$(jq '.summary.failed // 0' "$json_file")
        
        if [ "$failed_count" -gt 0 ]; then
            echo "<p><strong>Nombre d'échecs:</strong> $failed_count</p>" >> "$html_file"
            echo "<table>" >> "$html_file"
            echo "<tr><th>Check ID</th><th>Nom du Contrôle</th><th>Ressource</th><th>Fichier</th><th>Guide</th></tr>" >> "$html_file"
            
            # Extraction des échecs avec jq
            jq -r '.results.failed_checks[]? | 
                "<tr>" +
                "<td>" + .check_id + "</td>" +
                "<td>" + .check_name + "</td>" +
                "<td>" + .resource + "</td>" +
                "<td>" + .file_path + "</td>" +
                "<td><a href=\"" + .guideline + "\" target=\"_blank\">Doc</a></td>" +
                "</tr>"' "$json_file" >> "$html_file" 2>/dev/null
            
            echo "</table>" >> "$html_file"
        else
            echo "<p class='passed'>✅ Aucun échec détecté</p>" >> "$html_file"
        fi
        
        echo "</div>" >> "$html_file"
    fi
done

cat >> "$html_file" << 'EOF'
    
    <h2>Recommandations</h2>
    <ul>
        <li>Consultez les fichiers JSON dans le dossier <code>reports_checkov/</code> pour les détails spécifiques</li>
        <li>Priorisez la correction des échecs critiques de sécurité</li>
        <li>Vérifiez la conformité Terraform et Kubernetes</li>
        <li>Assurez-vous qu'aucun secret n'est exposé dans le code</li>
    </ul>
    
    <hr>
    <p style="text-align: center; color: #95a5a6;">
        Rapport généré par Checkov - Infrastructure as Code Security Scanner
    </p>
</body>
</html>
EOF

echo "✓ Rapport HTML généré: $html_file"

# Génère le PDF si wkhtmltopdf est disponible
if command -v wkhtmltopdf &> /dev/null; then
    echo "Conversion du rapport HTML en PDF..."
    pdf_file="reports_checkov/rapport_tp6.pdf"
    wkhtmltopdf "$html_file" "$pdf_file" 2>/dev/null
    echo "✓ Rapport PDF généré: $pdf_file"
elif command -v google-chrome &> /dev/null || command -v chromium &> /dev/null; then
    echo "Conversion du rapport HTML en PDF avec Chrome/Chromium..."
    pdf_file="reports_checkov/rapport_tp6.pdf"
    chrome_cmd=$(command -v google-chrome || command -v chromium)
    $chrome_cmd --headless --disable-gpu --print-to-pdf="$pdf_file" "$html_file" 2>/dev/null
    echo "✓ Rapport PDF généré: $pdf_file"
else
    echo "⚠ wkhtmltopdf ou Chrome/Chromium non trouvé."
    echo "  Pour installer wkhtmltopdf: sudo apt-get install wkhtmltopdf"
    echo "  Le rapport HTML est disponible: $html_file"
    pdf_file=""
fi

echo ""
echo "========================================="
echo "✓ Le scan est terminé!"
echo "========================================="
echo ""
echo "📄 Rapports générés:"
echo "  • Markdown (pour IA): $md_file"
echo "  • HTML (navigateur): $html_file"
if [ -n "$pdf_file" ] && [ -f "$pdf_file" ]; then
    echo "  • PDF: $pdf_file"
fi
echo "  • JSON détaillés: ./reports_checkov/*.json"
echo ""
echo "📊 Résumé:"
echo "  • Total contrôles: $total_checks"
echo "  • ✅ Réussis: $total_passed"
echo "  • ❌ Échoués: $total_failed"
echo "  • 📈 Taux conformité: $success_rate%"
echo ""
echo "========================================="
