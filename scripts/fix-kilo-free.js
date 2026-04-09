const fs = require('fs');
const path = require('path');
const os = require('os');

const configPath = path.join(os.homedir(), '.openclaw', 'openclaw.json');

console.log('--- OpenClaw Kilo Free Injector ---');

if (!fs.existsSync(configPath)) {
    console.error('❌ Config file not found at: ' + configPath);
    console.error('   Please run "oa onboard" to configure Kilocode first.');
    process.exit(1);
}

try {
    const content = fs.readFileSync(configPath, 'utf8');
    const config = JSON.parse(content);

    if (!config.models || !config.models.providers || !config.models.providers.kilocode) {
        console.error('❌ Kilocode provider not found in your configuration.');
        console.error('   Add Kilocode via "oa onboard" before running this fix.');
        process.exit(1);
    }

    const kilo = config.models.providers.kilocode;
    const freeModelId = 'kilo-auto/free';
    const providerApi = kilo.api || 'openai-completions';

    // 1. Add Kilo Free to the provider if it doesn't exist
    if (!kilo.models) kilo.models = [];
    const exists = kilo.models.some(m => m.id === freeModelId);
    
    if (!exists) {
        kilo.models.push({
            id: freeModelId,
            name: "Kilo Free (Unlimited)",
            api: providerApi,
            reasoning: true,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 128000,
            maxTokens: 32768
        });
        console.log('✅ Added "' + freeModelId + '" to provider models list.');
    } else {
        console.log('ℹ️  "' + freeModelId + '" already exists in provider models.');
    }

    // 2. Set as primary model safely
    if (!config.agents) config.agents = {};
    if (!config.agents.defaults) config.agents.defaults = {};
    if (!config.agents.defaults.model) config.agents.defaults.model = {};

    if (config.agents.defaults.model.primary !== `kilocode/${freeModelId}`) {
        config.agents.defaults.model.primary = `kilocode/${freeModelId}`;
        console.log('✅ Updated primary agent model to: kilocode/' + freeModelId);
    }

    // 3. Set alias for clean UI safely
    if (!config.agents.defaults.models) config.agents.defaults.models = {};
    if (!config.agents.defaults.models[`kilocode/${freeModelId}`]) {
        config.agents.defaults.models[`kilocode/${freeModelId}`] = { alias: "Kilo Free" };
        console.log('✅ Added "Kilo Free" alias to agent defaults.');
    }

    // 4. Atomic write
    const tempPath = configPath + '.tmp';
    fs.writeFileSync(tempPath, JSON.stringify(config, null, 2));
    fs.renameSync(tempPath, configPath);

    console.log('🚀 Configuration successfully optimized for Free tier.');
} catch (e) {
    console.error('❌ Failed to inject config: ' + e.message);
    process.exit(1);
}
