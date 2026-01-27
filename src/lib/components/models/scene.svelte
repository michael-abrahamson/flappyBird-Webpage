<script lang="ts">
  import type * as THREE from 'three'
  import { T } from '@threlte/core'
  import { useGltf } from '@threlte/extras'

  // Props you can modify from parent
  export let ref: THREE.Group | null = null
  export let position: [number, number, number] = [0, 0, 0]
  export let rotation: [number, number, number] = [-Math.PI / 2, 0, 0]
  export let scale: number = 100

  // Load the gltf
  type GLTFResult = {
    nodes: {
      main_jsf_mainMat_0: THREE.Mesh
      main_jsf_mainMat_0_1: THREE.Mesh
      aux_jsf_auxMat_0: THREE.Mesh
      aux_jsf_auxMat_0_1: THREE.Mesh
    }
    materials: {
      jsf_mainMat: THREE.MeshStandardMaterial
      jsf_auxMat: THREE.MeshStandardMaterial
    }
  }

  const gltf = useGltf<GLTFResult>('/models/scene.gltf')
</script>

<T.Group bind:this={ref} position={position} rotation={rotation} scale={scale} dispose={false}>
  {#await gltf}
    <!-- optional loading fallback -->
    <T.Mesh />
  {:then gltf}
    <!-- main material meshes -->
    <T.Group rotation={rotation} scale={scale}>
      <T.Mesh geometry={gltf.nodes.main_jsf_mainMat_0.geometry} material={gltf.materials.jsf_mainMat} />
      <T.Mesh geometry={gltf.nodes.main_jsf_mainMat_0_1.geometry} material={gltf.materials.jsf_mainMat} />
    </T.Group>

    <!-- aux material meshes -->
    <T.Group rotation={rotation} scale={scale}>
      <T.Mesh geometry={gltf.nodes.aux_jsf_auxMat_0.geometry} material={gltf.materials.jsf_auxMat} />
      <T.Mesh geometry={gltf.nodes.aux_jsf_auxMat_0_1.geometry} material={gltf.materials.jsf_auxMat} />
    </T.Group>
  {:catch error}
    <p>Error loading model: {error.message}</p>
  {/await}
</T.Group>
