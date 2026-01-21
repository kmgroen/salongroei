import { ui, defaultLang } from './config';

export function getLangFromUrl(url: URL) {
  const [, lang] = url.pathname.split('/');
  if (lang in ui) return lang as keyof typeof ui;
  return defaultLang;
}

export function useTranslations(lang: keyof typeof ui) {
  return function t(key: keyof typeof ui[typeof defaultLang]) {
    return ui[lang][key] || ui[defaultLang][key];
  }
}

export function getLocalizedPath(path: string, lang: string) {
  // Remove leading slash if present
  const cleanPath = path.startsWith('/') ? path.slice(1) : path;

  // If default language, return path without prefix
  if (lang === defaultLang) {
    return `/${cleanPath}`;
  }

  // For other languages, add language prefix
  return `/${lang}/${cleanPath}`;
}

export function removeLocalizedPath(url: URL) {
  const pathParts = url.pathname.split('/').filter(Boolean);

  // If first part is a language code, remove it
  if (pathParts[0] in ui) {
    pathParts.shift();
  }

  return '/' + pathParts.join('/');
}
