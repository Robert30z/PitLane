# PitLane — plan de arranque (19 julio 2026)

## La verdad del estado actual
- **0 listings** en el mercado
- **2 usuarios**: Trippzy (tú) y Pwnish (Yamil Santoni, registrado 7 julio)
- 0 clanes, 0 mensajes, 0 DMs, 0 reseñas, 0 RSVPs, 0 suscripciones de push
- 1 evento

La app tiene ~50 features y está vacía. **El cuello de botella no son features, es
que no hay inventario ni gente.** Un marketplace vacío no convierte: el visitante
entra, ve la nada, y no vuelve.

## Regla de oro: NO invitar a nadie hasta que haya listings
Primero inventario, después gente. Al revés se quema el primer contacto y esa
persona no vuelve una segunda vez.

---

## PASO 1 — Sembrar 5-10 listings (tarea de Roberto)
Publica lo que sea real y tuyo. Sirve cualquier cosa con motor o piezas:
- piezas que tengas guardadas del taller
- algo de tu carro que cambiaste y sacaste
- herramienta que ya no uses
- si tienes un carro/moto/ATV a la venta, ese primero

**No hace falta que se vendan.** Hacen falta para que el mercado no esté vacío
cuando llegue el primer visitante de verdad.

Cada listing pide 6 fotos reales (4 si es pieza). Eso es a propósito: es lo que
hace a PitLane mejor que un grupo de Facebook. No lo brinques.

---

## PASO 2 — Escribirle a Yamil (Pwnish)
Es tu único usuario real y se registró solo. Eso significa que algo le llamó la
atención. Nunca volvió — y saber POR QUÉ vale más que 10 features nuevas.

> Yamil, Roberto de PitLane. Vi que te registraste hace par de semanas y no
> volviste, y en vez de adivinar prefiero preguntarte directo: ¿qué te faltó?
> ¿estaba vacío, no entendiste pa qué era, o simplemente no era lo tuyo?
> Dímelo crudo, no me ofendo, me sirve más la verdad que un cumplido.
> Ya le metí mano y ahora puedes compartir cualquier listing directo a WhatsApp
> o a un grupo. Si te digo cuándo hay carros publicados, ¿le das otra mirada?

⚠️ Escríbele DESPUÉS de tener los listings del paso 1, no antes.

---

## PASO 3 — Distribución: los grupos de clasificados por modelo
Hallazgo del 18 julio (ver `HQ\Pit Stop\GRUPOS-FB-PLAN.md`): la gente que compra y
vende carros en PR vive en grupos de FB **por modelo específico** — Clasificados
Corolla 98-2002, Corolla 03-08, Ford Ranger/Mazda, Veloster PR, Cherokee PR, más
los clasificados de carros donde ya estás.

**Esa gente es exactamente el usuario de PitLane.** Están usando un formato horrible
para vender carros: sin fotos obligatorias, sin VIN, sin reputación, sin historial.

Y aquí está lo bueno: esos grupos **solo aceptan listings** — que es precisamente
lo que tú vas a postear. No es autopromoción, es un anuncio de venta, que es a lo
que el grupo está hecho.

### Cómo se hace (con la feature nueva)
1. Publica el carro/pieza en PitLane
2. Abre el listing → **🔗 Share this listing** → **📋 Copy text + link**
3. Pega eso en el grupo del modelo que corresponda
4. Quien toque el link cae directo en tu listing, sin registrarse, y ve las 6
   fotos, el VIN y las specs

El texto sale así:
> Vendo: 2003 Honda Accord EX — $4,500 · Bayamón, PR
> Fotos, VIN y specs completos en PitLane:
> https://robert30z.github.io/PitLane/?l=...

**No menciones "mi app" en el grupo.** Vende el carro. El link hace el trabajo solo
y la gente pregunta sola qué es PitLane.

---

## Qué se construyó el 19 julio (v1.6, 232fb3e — LIVE)
- **🔗 Share this listing** en cada listing: copiar link · WhatsApp · copiar
  texto+link para grupos · tarjeta 1080×1350 para historia (usa la primera foto real)
- **Deep links de listing** `?l=<id>` — abre el listing directo, sin login
- **🐛 BUG VIEJO ARREGLADO**: los links de perfil `?u=PL-####` **estaban rotos en
  producción** — el arranque resetea la vista varias veces y openDeep() olvidaba su
  objetivo al primer intento, así que el link caía en el mercado en vez del perfil.
  O sea: el QR de invitación y el link de tu bio de IG **nunca funcionaron bien**.
  Ya funcionan los dos.

## Pendiente / próximo
- **Importar listing desde foto con IA** (subes foto → llena marca/modelo/año/desc).
  NO se puede hacer solo en el cliente: haría falta poner una API key de Anthropic
  dentro del index.html, que es público → cualquiera la usa y tú pagas. La forma
  correcta es una edge function de Supabase (ya existe el patrón con `push`) con la
  key en secrets. **Requiere que Roberto ponga ANTHROPIC_API_KEY en Supabase.**
- Stripe Payment Links (pendiente desde hace rato — Pit Pass Pro / boost $15 / merch)
- Push nunca se probó en un teléfono real de punta a punta
