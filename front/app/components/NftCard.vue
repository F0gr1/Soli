<script setup lang="ts">
import type { OwnedToken } from "../types/deployment";

defineProps<{
  items: OwnedToken[];
}>();
</script>

<template>
  <section class="collection" aria-labelledby="collection-title">
    <div class="section-heading">
      <div>
        <p class="eyebrow">ON-CHAIN COLLECTION</p>
        <h2 id="collection-title">Your minted pieces</h2>
      </div>
      <span class="count">{{ items.length.toString().padStart(2, "0") }}</span>
    </div>

    <div v-if="items.length" class="token-grid">
      <article v-for="item in items" :key="item.tokenId" class="token-card">
        <div class="token-number">#{{ item.tokenId }}</div>
        <div class="token-orbit" aria-hidden="true"><span /></div>
        <p class="token-label">Metadata URI</p>
        <a :href="item.uri" target="_blank" rel="noreferrer" class="token-uri">{{ item.uri }}</a>
      </article>
    </div>
    <p v-else class="empty-state">Connect a wallet to load your collection, then mint the first piece.</p>
  </section>
</template>

<style scoped>
.collection {
  border-top: 1px solid rgba(20, 34, 37, 0.16);
  margin-top: 4rem;
  padding-top: 1.5rem;
}

.section-heading {
  align-items: flex-start;
  display: flex;
  justify-content: space-between;
  margin-bottom: 1.5rem;
}

.eyebrow,
.token-label {
  color: #967255;
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.18em;
  margin: 0 0 0.45rem;
  text-transform: uppercase;
}

h2 {
  color: #142225;
  font-family: Georgia, "Times New Roman", serif;
  font-size: clamp(1.7rem, 4vw, 2.35rem);
  font-weight: 500;
  margin: 0;
}

.count {
  color: #967255;
  font-family: Georgia, "Times New Roman", serif;
  font-size: 2.5rem;
  line-height: 1;
}

.token-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
}

.token-card {
  background: #e6ebe7;
  min-height: 235px;
  overflow: hidden;
  padding: 1.2rem;
  position: relative;
}

.token-number {
  color: #142225;
  font-family: Georgia, "Times New Roman", serif;
  font-size: 1.25rem;
  position: relative;
  z-index: 1;
}

.token-orbit {
  align-items: center;
  background: #b9cfc5;
  border: 1px solid rgba(20, 34, 37, 0.25);
  border-radius: 50%;
  display: flex;
  height: 145px;
  justify-content: center;
  margin: -0.5rem auto 1rem;
  transform: rotate(-17deg);
  width: 145px;
}

.token-orbit::before,
.token-orbit::after,
.token-orbit span {
  border: 1px solid rgba(20, 34, 37, 0.3);
  border-radius: 50%;
  content: "";
  height: 75%;
  position: absolute;
  transform: rotate(64deg) skewX(-12deg);
  width: 32%;
}

.token-orbit::after {
  height: 32%;
  transform: rotate(26deg) skewY(-12deg);
  width: 75%;
}

.token-orbit span {
  background: #e8b36d;
  border: 0;
  height: 22%;
  transform: none;
  width: 22%;
}

.token-uri {
  color: #142225;
  display: block;
  font-size: 0.8rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.empty-state {
  color: #526467;
  margin: 0;
}
</style>
