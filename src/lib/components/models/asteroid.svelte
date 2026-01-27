<script lang="ts">
  import type * as THREE from 'three'
  import { T } from '@threlte/core'
  import { useGltf } from '@threlte/extras'

  /** Public props (game-friendly) */
  export let ref: THREE.Group | null = null
  export let position: [number, number, number] = [0, 0, 0]
  export let rotation: [number, number, number] = [-Math.PI / 2, 0, 0]
  export let scale: number = 1

  /** GLTF typing */
  type GLTFResult = {
    nodes: {
      Object_2: THREE.Mesh
    }
    materials: {
      Asteroid: THREE.MeshStandardMaterial
    }
  }

  const gltf = useGltf<GLTFResult>('/models/asteroid.gltf')
</script>

<T.Group
  bind:this={ref}
  position={position}
  rotation={rotation}
  scale={scale}
  dispose={false}
>
  {#await gltf}
    <!-- Optional loading placeholder -->
    <T.Mesh />
  {:then gltf}
    <T.Mesh
      geometry={gltf.nodes.Object_2.geometry}
      material={gltf.materials.Asteroid}
    />
  {:catch error}
    <p>Error loading asteroid: {error.message}</p>
  {/await}
</T.Group>
