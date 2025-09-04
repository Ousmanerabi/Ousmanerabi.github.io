---
title: "Key Projects (2020–2024)"
layout: page
permalink: /projects/
classes: wide
toc: false
summary: "Selected projects in epidemiology, analytics, modeling, and training."
---

<!-- ========== STYLE LOCAL (simple et discret) ========== -->
<style>
  .page__content p.lead{font-size:1.05rem; line-height:1.6;}
  .projects-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px;margin-top:.5rem}
  .project-card{border:1px solid #eee;border-radius:12px;padding:16px;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.06)}
  .project-card a{font-weight:600;display:block;margin-bottom:4px}
  .project-meta{font-size:.9rem;opacity:.8}
  .search{max-width:640px;margin:.75rem 0 1.25rem}
  .search input{width:100%;padding:.75rem 1rem;border:1px solid #ddd;border-radius:999px}
</style>

<p class="lead">
Below is a curated selection of projects I led or contributed to between 2020 and 2024. Each page summarizes the context, methods, deliverables, and impact.
</p>

<div class="search">
  <input id="proj-search" type="text" placeholder="Filter by title, tag, or keyword…">
</div>

<!-- Image en chemin absolu pour éviter l'alt qui s'affiche -->
<figure>
  <img src="/Users/ousmanediallo/Documents/GitHub/Ousmanerabi.github.io/assets/projects/itn/timeline.png" alt="Timeline for key projects" style="max-width:100%;border-radius:12px;">
  <figcaption style="font-size:.9rem;opacity:.8;">Timeline for key projects</figcaption>
</figure>

## Thematic Areas
- **Modeling**: Scenario modeling to guide policy.  
- **Analytics**: Statistical and geospatial analysis for decision-making.  
- **SNT Support**: Data pipelines, stratification, and intervention targeting.  
- **Training**: Capacity building for graduate students.

## Projects
<div id="projects" class="projects-grid">

  <div class="project-card" data-tags="analytics epidemiology dhs itn guinea">
    <a href="/projects/risk_factors.html">Risk Factors – ITN Guinea DHS 2018</a>
    <div class="project-meta">2021–2022</div>
  </div>

  <div class="project-card" data-tags="burkina incidence trend mapping hmIS">
    <a href="/projects/retrospective_analysis.html">Retrospective Analysis of Malaria Trend in Burkina Faso</a>
    <div class="project-meta">2023–2024</div>
  </div>

  <div class="project-card" data-tags="burkina guinea togo targeting stratification snt">
    <a href="/projects/snt-stratification-targeting.md">Data Management, Stratification & Intervention Targeting (Togo, Guinea, Burkina Faso)</a>
    <div class="project-meta">2023</div>
  </div>

  <div class="project-card" data-tags="microstrat conakry mapping">
    <a href="/projects/microstratification-conakry.md">Microstratification in Conakry</a>
    <div class="project-meta">2023–2024</div>
  </div>

  <div class="project-card" data-tags="mentorship training supervision">
    <a href="/projects/training-mentorship-2020-2024.md">Training & Mentorship (Graduate Students – Benin & Guinea)</a>
    <div class="project-meta">2020–2024</div>
  </div>

</div>

<script>
  const input = document.getElementById('proj-search');
  const cards = [...document.querySelectorAll('#projects .project-card')];
  input?.addEventListener('input', e => {
    const q = e.target.value.trim().toLowerCase();
    cards.forEach(c => {
      const t = (c.textContent || '').toLowerCase() + ' ' + (c.dataset.tags || '');
      c.style.display = t.includes(q) ? '' : 'none';
    });
  });
</script>
