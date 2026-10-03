<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { supabase } from '../lib/supabase'
import { session } from '../lib/session'
import { urls } from '../lib/photos'

const uid = session.value!.user.id
const video = ref<HTMLVideoElement | null>(null)
const consent = ref(false)
const state = ref<'idle' | 'loading' | 'run' | 'done'>('idle')
const instr = ref('')
const result = ref('')
const err = ref('')
const verified = ref(false)
let stream: MediaStream | null = null
let stop = false

onMounted(async () => {
  const { data } = await supabase.from('profiles').select('verified').eq('id', uid).maybeSingle()
  verified.value = !!data?.verified
})
onUnmounted(() => cleanup())

function cleanup() {
  stop = true
  stream?.getTracks().forEach(t => t.stop())
  stream = null
}
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
function loadImg(src: string) {
  return new Promise<HTMLImageElement>((res, rej) => {
    const i = new Image()
    i.crossOrigin = 'anonymous'
    i.onload = () => res(i)
    i.onerror = () => rej(new Error("Impossible de charger une photo de profil."))
    i.src = src
  })
}

async function start() {
  err.value = ''
  result.value = ''
  stop = false
  if (!consent.value) { err.value = "Vous devez accepter le traitement de votre image."; return }
  state.value = 'loading'
  try {
    const faceapi = await import('@vladmandic/face-api')
    const opts = new faceapi.TinyFaceDetectorOptions({ inputSize: 320, scoreThreshold: 0.5 })
    await Promise.all([
      faceapi.nets.tinyFaceDetector.loadFromUri('/models'),
      faceapi.nets.faceLandmark68Net.loadFromUri('/models'),
      faceapi.nets.faceRecognitionNet.loadFromUri('/models'),
      faceapi.nets.faceExpressionNet.loadFromUri('/models')
    ])
    const { data: prof } = await supabase.from('profiles').select('photo_paths').eq('id', uid).single()
    const refs: Float32Array[] = []
    for (const u of await urls(prof!.photo_paths)) {
      const d = await faceapi.detectSingleFace(await loadImg(u), opts).withFaceLandmarks().withFaceDescriptor()
      if (d) refs.push(d.descriptor)
    }
    if (!refs.length) throw new Error("Aucun visage détectable sur vos photos de profil. Ajoutez une photo de face nette.")

    stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user', width: 640, height: 480 }, audio: false })
    const v = video.value!
    v.srcObject = stream
    await v.play()
    state.value = 'run'

    const challenge = Math.random() < 0.5 ? 'smile' : 'turn'
    let phase: 'front' | 'chal' = 'front'
    let desc: Float32Array | null = null
    let blob: Blob | null = null
    let ok = false
    const t0 = Date.now()
    instr.value = "Placez votre visage face caméra, bien éclairé."

    while (!stop && Date.now() - t0 < 30000) {
      await sleep(250)
      const base = faceapi.detectSingleFace(v, opts).withFaceLandmarks().withFaceExpressions()
      const d: any = phase === 'front' ? await base.withFaceDescriptor() : await base
      if (!d) continue
      const j = d.landmarks.getJawOutline()
      const n = d.landmarks.getNose()[3]
      const ratio = (n.x - j[0].x) / (j[16].x - j[0].x)
      if (phase === 'front') {
        if (ratio > 0.4 && ratio < 0.6 && d.detection.box.width > v.videoWidth * 0.25) {
          const c = document.createElement('canvas')
          c.width = v.videoWidth
          c.height = v.videoHeight
          c.getContext('2d')!.drawImage(v, 0, 0)
          blob = await new Promise<Blob | null>(r => c.toBlob(r, 'image/jpeg', 0.85))
          desc = d.descriptor
          phase = 'chal'
          instr.value = challenge === 'smile' ? "Souriez franchement." : "Tournez lentement la tête sur le côté."
        }
      } else if (challenge === 'smile' ? d.expressions.happy > 0.85 : (ratio < 0.3 || ratio > 0.7)) {
        ok = true
        break
      }
    }
    if (!ok || !blob || !desc) throw new Error("Défi non réussi à temps. Réessayez dans un endroit bien éclairé.")

    const dist = Math.min(...refs.map(r => faceapi.euclideanDistance(r, desc!)))
    cleanup()
    instr.value = 'Envoi…'
    const path = `${uid}/${crypto.randomUUID()}.jpg`
    const up = await supabase.storage.from('selfies').upload(path, blob, { contentType: 'image/jpeg' })
    if (up.error) throw up.error
    const { data: st, error } = await supabase.rpc('submit_verification', { p_selfie: path, p_challenge: challenge, p_distance: dist, p_consent: true })
    if (error || st === 'rejected') await supabase.storage.from('selfies').remove([path])
    if (error) throw error
    if (st === 'verified') { verified.value = true; result.value = "Profil vérifié ✔" }
    else if (st === 'pending') result.value = "Vérification en cours : un modérateur doit valider votre selfie."
    else result.value = "Le selfie ne correspond pas assez à vos photos. Réessayez (3 essais par 24 h) ou ajoutez une photo de face plus nette."
    state.value = 'done'
  } catch (e: any) {
    cleanup()
    err.value = e?.message ?? "Erreur inattendue."
    state.value = 'idle'
  }
}
</script>

<template>
  <div class="space-y-3">
    <router-link to="/profile" class="text-sm text-rose-600">← Profil</router-link>
    <h1 class="text-lg font-bold">Vérifier mon profil</h1>
    <p v-if="verified" class="rounded-lg bg-green-100 p-3 text-green-900">Votre profil est vérifié ✔</p>
    <p class="text-sm text-zinc-500">Un selfie en direct (avec un petit geste à réaliser) est comparé automatiquement à vos photos de profil. Le badge rassure les autres membres.</p>
    <video v-show="state === 'run'" ref="video" playsinline muted class="w-full -scale-x-100 rounded-2xl bg-black"></video>
    <p v-if="state === 'run'" class="text-center font-semibold">{{ instr }}</p>
    <p v-if="state === 'loading'" class="text-center text-zinc-500">Préparation (chargement du modèle)…</p>
    <template v-if="state === 'idle' || state === 'done'">
      <label class="flex items-start gap-2 text-sm"><input v-model="consent" type="checkbox" class="mt-1" />
        <span>Je consens explicitement au traitement de mon image par reconnaissance faciale pour vérifier mon profil (voir <router-link to="/cgu" class="underline">CGU, art. 4</router-link>). Le selfie est supprimé après examen ou sous 30 jours.</span></label>
      <button class="btn w-full" @click="start">{{ state === 'done' ? 'Recommencer' : 'Démarrer la vérification' }}</button>
    </template>
    <p v-if="result" class="rounded-lg bg-rose-100 p-3 text-rose-900">{{ result }}</p>
    <p v-if="err" class="text-sm text-red-600">{{ err }}</p>
  </div>
</template>
