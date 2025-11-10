document.addEventListener("DOMContentLoaded", () => {
    const refsContainer = document.querySelector("#refs");
    if (!refsContainer) return;
  
    const entries = Array.from(refsContainer.querySelectorAll("div.csl-entry"));
  
    // --- Group by year and type ---
    const grouped = {};
    entries.forEach(entry => {
      const text = entry.innerText;
      const yearMatch = text.match(/\b(19|20)\d{2}\b/);
      const year = yearMatch ? yearMatch[0] : "Unknown";
  
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
  
    // --- Clear and rebuild sorted ---
    refsContainer.innerHTML = "";
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
  
    // --- Citation download helper ---
    function downloadCitation(doi, format, filename) {
      const url = `https://api.crossref.org/works/${doi}/transform/${format}`;
      fetch(url)
        .then(response => {
          if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
          return response.text();
        })
        .then(data => {
          const blob = new Blob([data], { type: "text/plain" });
          const downloadUrl = window.URL.createObjectURL(blob);
          const a = document.createElement("a");
          a.href = downloadUrl;
          a.download = filename;
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          window.URL.revokeObjectURL(downloadUrl);
        })
        .catch(() => window.open(url, "_blank"));
    }
  
    // --- Style each entry ---
    const allEntries = document.querySelectorAll("#refs > div.csl-entry");
    allEntries.forEach(entry => {
      // Clean up unwanted text
      entry.innerHTML = entry.innerHTML
        .replace(/\s\[(Internet|Online|Web|Print)\]/g, "")
        .replace(/Available\sfrom\:\s/g, "")
        .replace(/Diallo, Ousmane Oumou/g, "<strong>Diallo, Ousmane Oumou*</strong>")
        .replace(/Diallo O\b/g, "<strong>Diallo O*</strong>")
        .replace(/\.\s([A-Z][^.]*?)\.\s(\d{4})/g, ". <em>$1</em>. $2");
  
      // --- DOI detection ---
      let doi = null;
      const html = entry.innerHTML;
      const text = entry.innerText;
  
      const matchHtml = html.match(/https?:\/\/doi\.org\/(10\.\d{4,9}\/[-._;()/:A-Z0-9]+)/i);
      const matchText = text.match(/\b(10\.\d{4,9}\/[-._;()/:A-Z0-9]+)\b/i);
      const matchColon = text.match(/doi:\s*(10\.\d{4,9}\/[-._;()/:A-Z0-9]+)/i);
      doi = matchHtml?.[1] || matchText?.[1] || matchColon?.[1] || null;
  
      const doiUrl = doi ? `https://doi.org/${doi}` : null;
      const link = entry.querySelector("a[href]")?.getAttribute("href");
      const url = doiUrl || link;
  
      // --- DOI display (always at end) ---
      if (doiUrl) {
        entry.innerHTML = entry.innerHTML
          .replace(/https?:\/\/doi\.org\/10\.[^ <)]+/gi, "")
          .replace(/\s*DOI[:;]?\s*/gi, "");
        const doiLine = document.createElement("div");
        doiLine.innerHTML = `<a href="${doiUrl}" target="_blank" rel="noopener" class="doi-link">${doiUrl}</a>`;
        entry.appendChild(doiLine);
      }
  
      // --- Add action buttons ---
      const btns = document.createElement("div");
      btns.classList.add("pub-buttons");
  
      if (url) {
        const journalBtn = document.createElement("a");
        journalBtn.href = url;
        journalBtn.target = "_blank";
        journalBtn.textContent = "Journal";
        btns.appendChild(journalBtn);
  
        if (doi) {
          const bibBtn = document.createElement("button");
          bibBtn.textContent = "BibTeX";
          bibBtn.onclick = e => {
            e.preventDefault();
            const filename = `citation_${doi.replace(/[\/\.]/g, "_")}.bib`;
            downloadCitation(doi, "application/x-bibtex", filename);
          };
          btns.appendChild(bibBtn);
  
          const risBtn = document.createElement("button");
          risBtn.textContent = "RIS";
          risBtn.onclick = e => {
            e.preventDefault();
            const filename = `citation_${doi.replace(/[\/\.]/g, "_")}.ris`;
            downloadCitation(doi, "application/x-research-info-systems", filename);
          };
          btns.appendChild(risBtn);
        }
      }
  
      entry.appendChild(btns);
    });
  });
  