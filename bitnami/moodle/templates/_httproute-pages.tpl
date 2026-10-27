{{- /*
Paginas propias del sitio para Gateway API (datacurso fork, 28.0.10).
Diseno: "Sitio en Mantenimiento" de BuenData, convertido de Tailwind CDN a CSS
propio. AUTOCONTENIDO a proposito: una pagina de error tiene que verse bien
justamente cuando algo esta caido, asi que no carga nada externo salvo el logo
o la imagen que el cliente elija (opcionales).
*/}}

{{/*
Modo efectivo del sitio. Vacio o ausente = active.
*/}}
{{- define "moodle.httpRoute.mode" -}}
{{- $mode := .Values.httpRoute.mode | default "active" | toString | lower -}}
{{- if not (has $mode (list "active" "maintenance" "suspended")) -}}
{{- fail (printf "httpRoute.mode=%q invalido: usar active, maintenance o suspended" $mode) -}}
{{- end -}}
{{- $mode -}}
{{- end -}}

{{/*
Valida un color hex (#rgb o #rrggbb) para que un value mal escrito no inyecte CSS.
*/}}
{{- define "moodle.httpRoute.color" -}}
{{- if not (regexMatch "^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$" .value) -}}
{{- fail (printf "%s=%q invalido: usar #rgb o #rrggbb" .name .value) -}}
{{- end -}}
{{- .value -}}
{{- end -}}

{{/*
Valida una URL https (logo o imagen del cliente).
*/}}
{{- define "moodle.httpRoute.url" -}}
{{- if and .value (not (hasPrefix "https://" .value)) -}}
{{- fail (printf "%s debe empezar con https://" .name) -}}
{{- end -}}
{{- .value -}}
{{- end -}}

{{/*
Iconos (Heroicons, MIT) por tipo de pagina.
*/}}
{{- define "moodle.httpRoute.icon" -}}
{{- if eq . "maintenance" -}}
<svg class="spin" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.2" stroke="currentColor" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M10.34 3.94c.09-.542.56-.94 1.11-.94h1.1c.55 0 1.02.398 1.11.94l.15.894c.07.424.384.764.78.93.398.164.855.142 1.205-.108l.737-.527a1.125 1.125 0 0 1 1.45.12l.773.774c.39.389.44 1.002.12 1.45l-.527.737c-.25.35-.272.806-.107 1.204.165.397.505.71.93.78l.893.15c.543.09.94.56.94 1.109v1.094c0 .55-.397 1.02-.94 1.11l-.893.149c-.425.07-.765.383-.93.78-.165.398-.143.854.107 1.204l.527.738c.32.447.269 1.06-.12 1.45l-.774.773a1.125 1.125 0 0 1-1.449.12l-.738-.527c-.35-.25-.806-.272-1.203-.107-.397.165-.71.505-.781.929l-.149.894c-.09.542-.56.94-1.11.94h-1.1c-.55 0-1.02-.398-1.11-.94l-.15-.894c-.07-.424-.384-.764-.781-.93-.398-.164-.854-.142-1.204.108l-.738.527c-.447.32-1.06.269-1.45-.12l-.773-.774a1.125 1.125 0 0 1-.12-1.45l.527-.737c.25-.35.273-.806.108-1.204-.165-.397-.505-.71-.93-.78l-.894-.15c-.542-.09-.94-.56-.94-1.109v-1.094c0-.55.398-1.02.94-1.11l.894-.149c.424-.07.765-.383.93-.78.165-.398.143-.854-.107-1.204l-.527-.738a1.125 1.125 0 0 1 .12-1.45l.773-.773a1.125 1.125 0 0 1 1.45-.12l.737.527c.35.25.807.272 1.204.107.397-.165.71-.505.78-.929l.15-.894Z"/><path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"/></svg>
{{- else if eq . "suspended" -}}
<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.2" stroke="currentColor" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z"/></svg>
{{- else -}}
<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.2" stroke="currentColor" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"/></svg>
{{- end -}}
{{- end -}}

{{/*
Auto-recarga: cada 60 s consulta "/" y recarga SOLO si el sitio responde bien
(response.ok). Con "!== 503" una pagina de suspension (403) o de error (502/504)
se recargaria para siempre. No se incluye en suspended.
*/}}
{{- define "moodle.httpRoute.reload" -}}
<script>
(function(){
  function check(){
    fetch(window.location.origin + '/', {method:'HEAD', cache:'no-store', redirect:'follow'})
      .then(function(r){ if (r.ok) { window.location.reload(); } })
      .catch(function(){});
  }
  setInterval(check, 60000);
})();
</script>
{{- end -}}

{{/*
HTML de una pagina con la marca del cliente.
Uso: include "moodle.httpRoute.page" (dict "kind" "maintenance" "context" $)
  kind: maintenance | suspended | unavailable
Todo texto que viene de values pasa por `html`; colores y URLs se validan.
Si httpRoute.pages.<kind>.imageUrl esta definido, la pagina SOLO muestra esa
imagen (pieza grafica del cliente), con el titulo como texto alternativo.
*/}}
{{- define "moodle.httpRoute.page" -}}
{{- $ctx := .context -}}
{{- $kind := .kind -}}
{{- $pages := $ctx.Values.httpRoute.pages -}}
{{- $p := index $pages $kind -}}
{{- $b := $pages.brand -}}
{{- $name := $b.name | default $ctx.Values.ingress.hostname -}}
{{- $brand := include "moodle.httpRoute.color" (dict "name" "httpRoute.pages.brand.primaryColor" "value" ($b.primaryColor | default "#bd0b29")) -}}
{{- $bg := include "moodle.httpRoute.color" (dict "name" "httpRoute.pages.brand.backgroundColor" "value" ($b.backgroundColor | default "#000000")) -}}
{{- $logo := include "moodle.httpRoute.url" (dict "name" "httpRoute.pages.brand.logoUrl" "value" ($b.logoUrl | default "")) -}}
{{- $image := include "moodle.httpRoute.url" (dict "name" (printf "httpRoute.pages.%s.imageUrl" $kind) "value" ($p.imageUrl | default "")) -}}
{{- $reload := ne $kind "suspended" -}}
<!DOCTYPE html>
<html lang="{{ $b.lang | default "es" | html }}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex, nofollow">
<title>{{ $p.title | html }} | {{ $name | html }}</title>
{{- if $image }}
<style>
html,body{height:100%;margin:0}
body{display:flex;align-items:center;justify-content:center;background:{{ $bg }}}
img{display:block;max-width:100%;max-height:100vh;object-fit:contain}
</style>
</head>
<body>
<img src="{{ $image | html }}" alt="{{ $p.title | html }}. {{ $p.message | html }}">
{{- else }}
<style>
:root{
  --brand:{{ $brand }};
  --bg:{{ $bg }};
  /* fallback para navegadores sin color-mix (anteriores a 2023) */
  --brand-dark:{{ $brand }};
  --brand-soft:#f8fafc;
  --brand-line:#e2e8f0;
  --brand-glow:rgba(0,0,0,.12);
  --tint-a:#fff1f2;
  --tint-b:#ffe4e6;
  --ink:#1e293b;--text:#64748b;--text-2:#475569;--muted:#94a3b8;--panel:#f8fafc;--panel-line:#f1f5f9;
}
@supports (color: color-mix(in srgb, red, blue)){
  :root{
    --brand-dark:color-mix(in srgb, var(--brand) 72%, #000);
    --brand-soft:color-mix(in srgb, var(--brand) 6%, #fff);
    --brand-line:color-mix(in srgb, var(--brand) 16%, #fff);
    --brand-glow:color-mix(in srgb, var(--brand) 30%, transparent);
    --tint-a:color-mix(in srgb, var(--brand) 8%, #fff);
    --tint-b:color-mix(in srgb, var(--brand) 12%, #fff);
  }
}
*{box-sizing:border-box}
body{
  font-family:Inter,system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  background-color:var(--bg);
  background-image:radial-gradient(at 0% 0%, var(--tint-a) 0, transparent 50%),radial-gradient(at 100% 100%, var(--tint-b) 0, transparent 50%);
  background-attachment:fixed;
  min-height:100vh;margin:0;display:flex;align-items:center;justify-content:center;padding:1.5rem;
}
.bg-pattern{position:fixed;inset:0;background-image:radial-gradient(#cbd5e1 1px, transparent 1px);background-size:24px 24px;opacity:.3;z-index:0;pointer-events:none}
.card{
  position:relative;z-index:10;width:100%;max-width:580px;text-align:center;
  background:rgba(255,255,255,.95);-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px);
  border:1px solid rgba(255,255,255,.5);border-radius:2rem;padding:3.5rem 2.5rem;
  box-shadow:0 20px 25px -5px rgba(0,0,0,.05),0 8px 10px -6px rgba(0,0,0,.01),inset 0 0 0 1px rgba(255,255,255,.8);
}
.logo{display:block;max-height:25rem;max-width:min(25rem,100%);height:auto;margin:0 auto 1.75rem}
.badge{display:inline-flex;align-items:center;gap:.5rem;padding:.375rem .75rem;margin-bottom:2rem;border-radius:9999px;background:var(--brand-soft);border:1px solid var(--brand-line)}
.dot{position:relative;display:flex;width:.625rem;height:.625rem}
.dot i{position:absolute;inset:0;border-radius:9999px;background:var(--brand)}
.dot i:first-child{opacity:.75;animation:ping 1s cubic-bezier(0,0,.2,1) infinite}
.badge span{font-family:"Roboto Mono",ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:.75rem;font-weight:600;letter-spacing:.05em;text-transform:uppercase;color:var(--brand)}
.icon{width:6rem;height:6rem;margin:0 auto 2rem;border-radius:2rem;display:flex;align-items:center;justify-content:center;color:#fff;background:linear-gradient(to top right, var(--brand-dark), var(--brand));box-shadow:0 10px 15px -3px var(--brand-glow),0 4px 6px -4px var(--brand-glow);animation:pulse-soft 3s cubic-bezier(.4,0,.6,1) infinite}
.icon svg{width:3rem;height:3rem}
.icon .spin{animation:spin 12s linear infinite}
h1{margin:0 0 1rem;font-size:1.875rem;line-height:2.25rem;font-weight:800;letter-spacing:-.025em;color:var(--ink)}
.lead{max-width:28rem;margin:0 auto 2.5rem;font-size:1.125rem;line-height:1.625;font-weight:300;color:var(--text)}
.info{display:flex;align-items:flex-start;gap:1rem;text-align:left;margin-bottom:2rem;padding:1.25rem;border-radius:.75rem;background:var(--panel);border:1px solid var(--panel-line)}
.info svg{flex-shrink:0;width:1.5rem;height:1.5rem;margin-top:.25rem;color:var(--muted)}
.info h3{margin:0 0 .25rem;font-size:1rem;font-weight:600;color:var(--ink)}
.info p{margin:0;font-size:.875rem;line-height:1.25rem;color:var(--text-2)}
.info a{color:var(--brand);font-weight:600;text-decoration:none}
.wait{display:flex;justify-content:center;align-items:center;gap:.5rem;font-size:.875rem;font-weight:500;color:var(--muted)}
.dots{color:var(--brand)}
.dots i{display:inline-block;width:6px;height:6px;margin:0 2px;border-radius:50%;background:currentColor;animation:bounce 1.4s infinite ease-in-out both}
.dots i:nth-child(1){animation-delay:-.32s}
.dots i:nth-child(2){animation-delay:-.16s}
@keyframes ping{75%,100%{transform:scale(2);opacity:0}}
@keyframes spin{to{transform:rotate(360deg)}}
@keyframes bounce{0%,80%,100%{transform:scale(0)}40%{transform:scale(1)}}
@keyframes pulse-soft{0%{transform:scale(1);box-shadow:0 0 0 0 var(--brand-glow)}50%{transform:scale(1.03);box-shadow:0 0 0 15px transparent}100%{transform:scale(1);box-shadow:0 0 0 0 transparent}}
@media (min-width:768px){h1{font-size:2.25rem;line-height:2.5rem}.lead{font-size:1.25rem;line-height:1.75rem}}
@media (max-width:480px){.card{padding:2.5rem 1.5rem;border-radius:1.5rem}}
@media (prefers-reduced-motion:reduce){*,*::before,*::after{animation:none !important}}
</style>
</head>
<body>
<div class="bg-pattern"></div>
<main class="card">
{{- if $logo }}
<img class="logo" src="{{ $logo | html }}" alt="{{ $name | html }}">
{{- end }}
<div class="badge"><span class="dot"><i></i><i></i></span><span>{{ $p.badge | html }}</span></div>
<div class="icon">{{ include "moodle.httpRoute.icon" $kind }}</div>
<h1>{{ $p.title | html }}</h1>
<p class="lead">{{ $p.message | html }}</p>
{{- if or $p.infoTitle $p.infoMessage $b.contactEmail }}
<div class="info">
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zm8.706-1.442c1.146-.573 2.437.463 2.126 1.706l-.709 2.836.042-.02a.75.75 0 01.67 1.34l-.04.022c-1.147.573-2.438-.463-2.127-1.706l.71-2.836-.042.02a.75.75 0 11-.671-1.34l.041-.022zM12 9a.75.75 0 100-1.5.75.75 0 000 1.5z" clip-rule="evenodd"/></svg>
<div>
{{- if $p.infoTitle }}
<h3>{{ $p.infoTitle | html }}</h3>
{{- end }}
{{- if $p.infoMessage }}
<p>{{ $p.infoMessage | html }}</p>
{{- end }}
{{- if $b.contactEmail }}
<p>Soporte: <a href="mailto:{{ $b.contactEmail | html }}">{{ $b.contactEmail | html }}</a></p>
{{- end }}
</div>
</div>
{{- end }}
{{- if $p.waitingText }}
<div class="wait">{{ $p.waitingText | html }} <span class="dots"><i></i><i></i><i></i></span></div>
{{- end }}
</main>
{{- end }}
{{- if $reload }}
{{ include "moodle.httpRoute.reload" . }}
{{- end }}
</body>
</html>
{{- end -}}
