<script lang="ts">
	import { T, useRender, useThrelte, useFrame, useTask } from '@threlte/core';
	import { ContactShadows, Float, Grid, OrbitControls } from '@threlte/extras';
	import {
		MeshBasicMaterial,
		PlaneGeometry,
		Raycaster,
		SphereGeometry,
		Vector2,
		Mesh,
		Color,
		Vector3,
		CylinderGeometry,
		PMREMGenerator
	} from 'three';
	import { onMount } from 'svelte';
	import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
	import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
	import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
	import { damp, degToRad } from 'three/src/math/MathUtils.js';

	let planeRef; //check intersection with objects
	let player; //Bird
	let pillarRef;

	const { scene, camera, renderer } = useThrelte();

	const composer = new EffectComposer(renderer);
	composer.setSize(innerWidth, innerHeight);

	const setupEffectComposer = () => {
		const renderPass = new RenderPass(scene, camera.current);
		composer.addPass(renderPass);

		const bloomPass = new UnrealBloomPass(new Vector2(innerWidth, innerHeight), 0.275, 1, 0);
		composer.addPass(bloomPass);

		const outputPass = new OutputPass();
		composer.addPass(outputPass);
	};

	useRender(({ scene }) => {

		composer.render();
	});

	const gravityAcc = -30;
	const upwardAcc = 3;

	let xAcc = 0;

	//spring motion/damping -> s.t we do not just teleport the player but, it has a smooth motion over time
	let yVel = 0; //velocity
	let y = 0; //position
	const damping = 0.9;
	const stiffness = 0.02


	useTask((delta) => { //ran every frame -> used for game logic, can be throttled
		updatePlayerYPos(delta);
	});
	onMount(() => {
		//this section only runs once on creation
		setupEffectComposer();
	});

	function updatePlayerYPos(delta) {
		yVel += gravityAcc * delta;

		yVel *= damping;

		y += yVel * delta;
	}


	/**
	 * On keyboard "space" click, an upward velocity is added to the yVel
	 * Spring motion must be added such that there is a stiffness and damping
	 * @param event
	 */
	function onClick(event) {
		y += upwardAcc;
	}
	function handleKeyDown(event) {
		y += upwardAcc;
	}
</script>

<svelte:window on:keydown={handleKeyDown} on:click={onClick}/>

<T.PerspectiveCamera makeDefault position.x={-5 + xAcc} position.y={6} position.z={10} fov={40}>
	<OrbitControls enableZoom={false} />
</T.PerspectiveCamera>

<T.DirectionalLight intensity={1.8} position={[0, 10, 0]} castShadow shadow.bias={-0.0001} />
<T.AmbientLight intensity={0.2} />

<Grid
	position.y={-0.001}
	cellColor="#ffffff"
	sectionColor="#ffffff"
	sectionThickness={0}
	fadeDistance={25}
	cellSize={2}
	visible={false}
/>

<T.Mesh bind:ref={planeRef} visible={false}>
	<T.PlaneGeometry args={[20, 20]} />
	<T.MeshBasicMaterial color={[1, 0, 1]} transparent opacity={0.25} />
</T.Mesh>

<T.Mesh position.x={-1 + xAcc} position.z={0} bind:ref={player} visible={true} position.y={y}>
	<T.SphereGeometry args={[0.1, 20, 20]} />
	<T.MeshBasicMaterial color={[1, 0, 0]} />
</T.Mesh>

<!-- This should be on a timer to generate 2 cylinders
 Minimum gap between cylinders must exist, and then it expands to fill height
 It should get spawned outside of render, but.-->
<T.Mesh position.x={xAcc + 7} position.y={1} position.z={0}>
	<T.CylinderGeometry args={[0.4, 0.4, 2]} />
	<T.MeshBasicMaterial color={[1, 0, 1]} />
</T.Mesh>
