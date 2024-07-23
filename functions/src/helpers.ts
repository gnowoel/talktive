export const isDebugMode = () => process.env.FUNCTIONS_EMULATOR === "true";

export const getYear = (timestamp: Date) => timestamp.getUTCFullYear();

export const getMonth = (timestamp: Date) => ('0' + (timestamp.getUTCMonth() + 1)).slice(-2);

export const getDate = (timestamp: Date) => ('0' + timestamp.getUTCDate()).slice(-2);
