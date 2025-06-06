export const isDebugMode = () => process.env.FUNCTIONS_EMULATOR === "true";

export const formatDate = (timestamp: Date) => timestamp.toISOString().substring(0, 10).replace('-', '/').replace('-', '/');

export const getDateBasedDocId = (date?: Date) => {
  const targetDate = date || new Date();
  return targetDate.toISOString().split('T')[0]; // Returns YYYY-MM-DD format
};
