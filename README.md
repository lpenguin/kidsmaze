# kidsmaze

A maze game for kids built with Godot Engine.

## GitHub Pages Deployment

This project is automatically deployed to GitHub Pages when changes are pushed to the main branch. You can access the live version at: https://lpenguin.github.io/kidsmaze/

### Deployment Workflow

The deployment is handled by a GitHub Actions workflow that:

1. Exports the Godot project to a web build
2. Deploys the web build to GitHub Pages using GitHub's official Pages deployment actions

The workflow configuration can be found in `.github/workflows/export.yml`.

### Manual Deployment

You can also manually trigger a deployment from the GitHub Actions tab by selecting the "Export Godot Game and Deploy to GitHub Pages" workflow and clicking "Run workflow".
