export const isDebugMode = () => process.env.FUNCTIONS_EMULATOR === "true";

export const formatDate = (timestamp: Date) => timestamp.toISOString().substring(0, 10).replace('-', '/').replace('-', '/');
