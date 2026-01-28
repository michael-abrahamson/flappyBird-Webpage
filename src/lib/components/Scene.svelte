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
	import * as THREE from 'three';
	import { onMount } from 'svelte';
	import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
	import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
	import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
	import { damp, degToRad } from 'three/src/math/MathUtils.js';
	import JediStarFighter from './models/scene.svelte';
	import Asteroid from './models/asteroid.svelte';
	import { ThreeMFLoader } from 'three/examples/jsm/Addons.js';

	let planeRef: any; //check intersection with objects
	let player: any; //Bird
	let pillarRef: any; //obstacles
	let groundRef: any; //ground plane
	let ceilingRef: any; //ceiling plane

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

	//handle spawning of obstacles
	let obstacleSpawnTimer = 0;
	let obstacleSpawnInterval = 2; //seconds
	let obstacles: any[] = [];
	const obstacleSpeed = 5; //units per second

	function spawnObstacles() {
		let obstacle = {
			pos: new Vector3(12, Math.random() * 6 - 3, 0), //later on this wil be changed to spawn pipes similar to flappy bird with a minimum gap
			len: new Vector3(1, 1, 1),
			speed: obstacleSpeed,
			color: new Color(0xff0000)
		};
		obstacles.push(obstacle);
	}

	const gravityAcc = -30;
	const upwardAcc = 20;

	//spring damping -> s.t we do not just teleport the player but, it has a smooth motion over time
	let yVel = 0; //velocity
	let y = 1; //position
	const damping = 0.9;

	useTask((delta) => {
		//ran every frame -> used for game logic, can be throttled
		updatePlayerYPos(delta);
		updatePlayerTilt(delta);
		collisionDetection();

		obstacleSpawnTimer += delta;
		if (obstacleSpawnTimer >= obstacleSpawnInterval) {
			spawnObstacles();
			obstacleSpawnTimer = 0;
		}

		obstacles.forEach((obstacle) => {
			obstacle.pos.x -= obstacle.speed * delta;
			if (obstacle.pos.x <= -10) {
				removeObstacle(obstacles.indexOf(obstacle));
			}
		});
		obstacles = obstacles;
	});
	onMount(() => {
		//this section only runs once on creation
		setupEffectComposer();
	});

	function removeObstacle(index: number) {
		obstacles.splice(index, 1);
	}

	function updatePlayerYPos(delta: number) {
		yVel += gravityAcc * delta;

		yVel *= damping;

		y += yVel * delta;
	}

	function collisionDetection() {
		// basic collision detection between player + obstacles
		const playerBox = new THREE.Box3().setFromObject(player);
		obstacles.forEach((obstacle) => {
			// loop through obstacles
		});
		// Check collision with ground and ceiling
		if (y < -3.2 || y > 3.6) {
			console.log('Collision with ground or ceiling detected');
		}
	}
	const MAX_TILT = degToRad(30);
	const TILT_SPEED = 6;
	let tiltGroup: THREE.Group;

	function updatePlayerTilt(delta: number) {
		// tilt the player based on yVel
		if (!tiltGroup) return;

		//normalize vector to [-1, 1]
		const velNorm = THREE.MathUtils.clamp(yVel / upwardAcc, -1, 1);
		const targetTilt = yVel > 0 ? velNorm * MAX_TILT : velNorm * MAX_TILT * 0.6;
		// negative -> up is nose up

		//smooth interpolation
		tiltGroup.rotation.z = damp(tiltGroup.rotation.z, targetTilt, TILT_SPEED, delta);
	}

	/**
	 * On keyboard "space" click, an upward velocity is added to the yVel
	 * Spring motion must be added such that there is a stiffness and damping
	 * @param event
	 */
	function onClick(event: any) {
		yVel += upwardAcc;
	}
	function handleKeyDown(event: any) {
		yVel += upwardAcc;
	}
	/**
	 * Generates a random number between min and max
	 * @param min
	 * @param max
	 */
	function randomRange(min: number, max: number) {
		return Math.random() * (max - min) + min;
	}

	// section where we will generate stars i.e the light flashes decorating the scene

	const MAX_STARS = 500;
	let stars: any[] = [];
	for (let i = 0; i < MAX_STARS; i++) {
		let star = {
			pos: null,
			len: null,
			color: null,
			speed: null
		};

		stars.push(resetStar(star));
	}
	/**
	 * Here we will provide the stars with values
	 * @param star
	 */
	function resetStar(star) {

	}
</script>

<svelte:window on:keydown={handleKeyDown} on:click={onClick} />

<T.PerspectiveCamera
	makeDefault
	position.x={4}
	position.y={0}
	position.z={8}
	fov={50}
	enableZoom={false}
	enablePan={false}
></T.PerspectiveCamera>
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
	// invisible plane for raycasting
	<T.PlaneGeometry args={[20, 20]} />
	<T.MeshBasicMaterial color={[1, 0, 1]} transparent opacity={0.25} />
</T.Mesh>

<T.Mesh visible={true} bind:ref={groundRef} position={[0, -3.2, 0]} rotation={[-Math.PI / 2, 0, 0]}>
	<T.PlaneGeometry args={[50, 5]} />
	<T.MeshBasicMaterial color={[0.1, 0.2, 0.1]} />
</T.Mesh> //plane for ground layer

<T.Mesh visible={true} bind:ref={ceilingRef} position={[0, 3.6, 0]} rotation={[Math.PI / 2, 0, 0]}>
	<T.PlaneGeometry args={[50, 5]} />
	<T.MeshBasicMaterial color={[0.1, 0.1, 0.1]} />
</T.Mesh> //plane for ceiling layer

{#each obstacles as obstacle}
	// pillars /obstacles
	<T.Mesh position={[obstacle.pos.x, obstacle.pos.y, obstacle.pos.z]}>
		<T.CylinderGeometry args={[0.4, 0.4, 2]} />
		<T.MeshBasicMaterial color={obstacle.color} />
	</T.Mesh>
{/each}
<T.Group bind:ref={player} position={[-1, y, 0]}>
	<T.Group bind:ref={tiltGroup}>
		<T.AxesHelper args={[2]} />
		<T.Group >
			<JediStarFighter scale={0.4}  rotation={[0, -Math.PI / 2, -Math.PI / 2]}/>
		</T.Group>
	</T.Group>
</T.Group>
