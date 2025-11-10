document.addEventListener("DOMContentLoaded", () => {
  const refsContainer = document.querySelector("#refs");
  if (!refsContainer) return; // sécurité : rien à faire si pas de biblio

  const entries = Array.from(refsContainer.querySelectorAll("div.csl-entry"));

  // --- 1. Regroupement par année + type ---
  const grouped = {};
  entries.forEach(entry => {
    const text = entry.innerText || "";

    // Année = premier nombre AAAA trouvé, sinon "Unknown"
    const yearMatches = text.match(/\b(19|20)\d{2}\b/g);
    const year = (yearMatches && yearMatches.length > 0) 
      ? yearMatches[yearMatches.length - 1]   // dernière année trouvée
      : "Unknown";

    // Type (assez simple, mais suffisant)
    let type = "Other";
    const lower = text.toLowerCase();
    if (lower.includes("preprint") || lower.includes("biorxiv")) type = "Preprint";
    else if (lower.includes("conference") || lower.includes("american journal of tropical medicine and hygiene")) type = "Conference";
    else if (
      lower.includes("journal") ||
      lower.includes("scientific reports") ||
      lower.includes("malaria journal") ||
      lower.includes("journal of global antimicrobial resistance") ||
      lower.includes("international journal of environmental research and public health")
    ) type = "Journal Article";

    if (!grouped[year]) grouped[year] = {};
    if (!grouped[year][type]) grouped[year][type] = [];
    grouped[year][type].push(entry);
  });

  // On vide la biblio originale
  refsContainer.innerHTML = "";

  // Tri des années décroissant
  const years = Object.keys(grouped).sort((a, b) => b.localeCompare(a));

  years.forEach(year => {
    const yearHeader = document.createElement("h2");
    yearHeader.textContent = year;
    refsContainer.appendChild(yearHeader);

    Object.keys(grouped[year]).forEach(type => {
      const typeHeader = document.createElement("h3");
      typeHeader.textContent = type;
      refsContainer.appendChild(typeHeader);

      grouped[year][type].forEach(entry => {
        refsContainer.appendChild(entry);
      });
    });
  });

  // --- 2. Fonction pour télécharger les citations (CrossRef, facultatif si DOI dispo) ---
  function downloadCitation(doi, format, filename) {
    const url = `https://api.crossref.org/works/${doi}/transform/${format}`;
    
    fetch(url)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.text();
      })
      .then(data => {
        const blob = new Blob([data], { type: 'text/plain' });
        const downloadUrl = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = downloadUrl;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(downloadUrl);
      })
      .catch(error => {
        console.error('Error downloading citation:', error);
        // Fallback : ouvrir dans un nouvel onglet
        window.open(url, '_blank');
      });
  }

  // --- 3. Post-traitement de chaque entrée (mise en forme + boutons) ---
  const allEntries = document.querySelectorAll("#refs > div.csl-entry");
  allEntries.forEach(entry => {
    // Nettoyage de mentions type [Internet], "Available from:" etc.
    entry.innerHTML = entry.innerHTML.replace(/\s\[(Internet|Online|Web|Print)\]/g, '');
    entry.innerHTML = entry.innerHTML.replace(/Available\sfrom\:\s/g, '');

    // Mettre ton nom en gras dans la liste d'auteurs
    entry.innerHTML = entry.innerHTML
      .replace(/Diallo, Ousmane Oumou/g, '<strong>Diallo, Ousmane Oumou*</strong>')
      .replace(/Diallo O\b/g, '<strong>Diallo O*</strong>');

    // (Option) journal en italique quand le pattern s’y prête
    entry.innerHTML = entry.innerHTML.replace(/\.\s([A-Z][^.]*?)\.\s(\d{4})/g, '. <em>$1</em>. $2');

    let doi = null;
    const htmlContent = entry.innerHTML;
    const textContent = entry.innerText || "";

    // Méthode 1 : DOI dans un lien type https://doi.org/10.xxxx/...
    const doiUrlMatch = htmlContent.match(/https?:\/\/doi\.org\/(10\.\d{4,9}\/[-._;()/:A-Z0-9]+)/i);
    if (doiUrlMatch) {
      doi = doiUrlMatch[1];
    }

    // Méthode 2 : DOI nu dans le texte
    if (!doi) {
      const bareDoiMatch = textContent.match(/\b(10\.\d{4,9}\/[-._;()/:A-Z0-9]+)\b/i);
      if (bareDoiMatch) {
        doi = bareDoiMatch[1];
      }
    }

    // Méthode 3 : pattern "doi: 10.xxxx/..."
    if (!doi) {
      const doiColonMatch = textContent.match(/doi:\s*(10\.\d{4,9}\/[-._;()/:A-Z0-9]+)/i);
      if (doiColonMatch) {
        doi = doiColonMatch[1];
      }
    }

    const doiUrl = doi ? `https://doi.org/${doi}` : null;
    const link = entry.querySelector("a[href]")?.getAttribute("href");
    const url = doiUrl || link; // priorité au DOI, sinon n’importe quel lien

    // Replace raw DOI URLs with a clean "DOI" hyperlink
    if (doiUrl) {
    // Supprimer les longues URL brutes comme "https://doi.org/10.1371/journal.pone..."
        entry.innerHTML = entry.innerHTML.replace(
        /(https?:\/\/doi\.org\/10\.[^ <]+)/gi,
        `<a href="$1" target="_blank" rel="noopener" class="doi-link">DOI</a>`
        );
    }

    const btns = document.createElement("div");
    btns.classList.add("pub-buttons");

    if (url) {
      // Bouton vers le journal / article
      const journalBtn = document.createElement("a");
      journalBtn.href = url;
      journalBtn.target = "_blank";
      journalBtn.textContent = "Journal";
      btns.appendChild(journalBtn);

      // Boutons BibTeX / RIS seulement si DOI trouvé
      if (doi) {
        const bibBtn = document.createElement("button");
        bibBtn.textContent = "BibTeX";
        bibBtn.onclick = (e) => {
          e.preventDefault();
          const filename = `citation_${doi.replace(/[\/\.]/g, '_')}.bib`;
          downloadCitation(doi, 'application/x-bibtex', filename);
        };
        btns.appendChild(bibBtn);

        const risBtn = document.createElement("button");
        risBtn.textContent = "RIS";
        risBtn.onclick = (e) => {
          e.preventDefault();
          const filename = `citation_${doi.replace(/[\/\.]/g, '_')}.ris`;
          downloadCitation(doi, 'application/x-research-info-systems', filename);
        };
        btns.appendChild(risBtn);
      }
    }

    entry.appendChild(btns);
  });
});
